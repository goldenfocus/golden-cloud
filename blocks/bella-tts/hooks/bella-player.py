#!/usr/bin/env python3
"""Bella TTS streamer.

Finds the latest Claude Code assistant message and streams it through
ElevenLabs' streaming TTS endpoint, piping mp3 chunks directly into ffplay
so audio starts ~300ms after invocation. Stores PIDs in a state file so a
second hotkey press can kill playback mid-sentence.
"""
from __future__ import annotations

import glob
import json
import os
import re
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

STATE_DIR = Path.home() / ".claude" / "bella-tts"
STATE_DIR.mkdir(parents=True, exist_ok=True)
PID_FILE = STATE_DIR / "player.pid"
MODE_FILE = STATE_DIR / "player.mode"
CONFIG_FILE = STATE_DIR / "config.json"
LOG_FILE = STATE_DIR / "player.log"
POINTER_FILE = STATE_DIR / "active-transcript"
PROJECTS_DIR = Path.home() / ".claude" / "projects"

# Modes:
#   full    — read full latest assistant response (triggered by hotkey)
#   recap   — read first 1-2 sentences (triggered by Stop hook)
#   say     — read explicit text (triggered by bella-narrate.sh mid-turn)
MODE_FULL = "full"
MODE_RECAP = "recap"
MODE_SAY = "say"
RECAP_MAX_CHARS = 220

DEFAULT_VOICE_ID = "EXAVITQu4vr4xnSDxMaA"  # canonical Bella
DEFAULT_MODEL = "eleven_turbo_v2_5"          # ~250ms first-chunk latency


def log(msg: str) -> None:
    try:
        with LOG_FILE.open("a") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")
    except Exception:
        pass


def get_api_key() -> str | None:
    try:
        return subprocess.check_output(
            ["security", "find-generic-password",
             "-a", os.environ.get("USER", ""),
             "-s", "ELEVENLABS_API_KEY", "-w"],
            stderr=subprocess.DEVNULL,
        ).decode().strip() or None
    except subprocess.CalledProcessError:
        return None


def load_config() -> dict:
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text())
        except Exception:
            return {}
    return {}


def find_current_jsonl() -> str | None:
    """Prefer the pointer written by the Claude Code hook. Fall back to mtime."""
    if POINTER_FILE.exists():
        try:
            path = POINTER_FILE.read_text().strip()
            if path and os.path.isfile(path):
                return path
        except OSError:
            pass
    candidates = glob.glob(str(PROJECTS_DIR / "*" / "*.jsonl"))
    if not candidates:
        return None
    return max(candidates, key=os.path.getmtime)


def extract_latest_assistant_text(jsonl_path: str) -> str | None:
    """Scan JSONL tail in reverse, return text of the newest assistant turn."""
    try:
        with open(jsonl_path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            chunk = min(size, 800_000)
            f.seek(max(0, size - chunk))
            tail = f.read().decode(errors="ignore")
    except OSError as e:
        log(f"jsonl read error: {e}")
        return None

    for line in reversed(tail.strip().split("\n")):
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        msg = obj.get("message")
        if not isinstance(msg, dict) or msg.get("role") != "assistant":
            continue
        content = msg.get("content")
        parts: list[str] = []
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get("type") == "text":
                    t = c.get("text", "")
                    if t:
                        parts.append(t)
        elif isinstance(content, str):
            parts.append(content)
        text = "\n".join(parts).strip()
        if text:
            return text
    return None


# Regex patterns for markdown stripping
RE_FENCE = re.compile(r"```.*?```", re.DOTALL)
RE_INLINE = re.compile(r"`[^`\n]+`")
RE_TABLE_ROW = re.compile(r"^\s*\|.*\|\s*$", re.MULTILINE)
RE_HEADING = re.compile(r"^#+\s+", re.MULTILINE)
RE_BULLET = re.compile(r"^[\s]*[-*+]\s+", re.MULTILINE)
RE_BOLD = re.compile(r"\*\*([^*]+)\*\*")
RE_ITAL = re.compile(r"\*([^*]+)\*")
RE_LINK = re.compile(r"\[([^\]]+)\]\([^)]+\)")
RE_INSIGHT = re.compile(r"★\s*Insight[^─]*─+.*?─+", re.DOTALL)
RE_HRULE = re.compile(r"^[─-]{3,}$", re.MULTILINE)
RE_WS = re.compile(r"\s+")


def clean_for_speech(text: str) -> str:
    """Keep prose, drop code/tables/markdown noise and the insight blocks."""
    text = RE_INSIGHT.sub(" ", text)
    text = RE_FENCE.sub(" ", text)
    text = RE_INLINE.sub(" ", text)
    text = RE_TABLE_ROW.sub(" ", text)
    text = RE_HEADING.sub("", text)
    text = RE_BULLET.sub("", text)
    text = RE_BOLD.sub(r"\1", text)
    text = RE_ITAL.sub(r"\1", text)
    text = RE_LINK.sub(r"\1", text)
    text = RE_HRULE.sub(" ", text)
    # Common symbols → spoken words
    text = text.replace("→", " then ").replace("↺", " revert ")
    text = text.replace("✓", " done ").replace("🔥", " critical ")
    text = text.replace("🚨", " warning ").replace("🔊", " ")
    return RE_WS.sub(" ", text).strip()


def write_pid_file(mode: str, *pids: int) -> None:
    PID_FILE.write_text("\n".join(str(p) for p in pids) + "\n")
    MODE_FILE.write_text(mode + "\n")


def cleanup_pid_file() -> None:
    for f in (PID_FILE, MODE_FILE):
        try:
            f.unlink()
        except FileNotFoundError:
            pass


def extract_recap(cleaned: str, max_chars: int = RECAP_MAX_CHARS) -> str:
    """Take the opening sentences up to ~max_chars. Good-enough auto-summary."""
    if len(cleaned) <= max_chars:
        return cleaned
    # Split on sentence boundaries, rebuild until we exceed max_chars
    parts = re.split(r"(?<=[.!?])\s+", cleaned)
    out: list[str] = []
    total = 0
    for p in parts:
        if total + len(p) + 1 > max_chars and out:
            break
        out.append(p)
        total += len(p) + 1
    recap = " ".join(out).strip()
    if not recap:
        recap = cleaned[:max_chars].rsplit(" ", 1)[0]
    if recap and recap[-1] not in ".!?…":
        recap += "…"
    return recap


def stream_tts(text: str, voice_id: str, model: str, api_key: str, mode: str = MODE_FULL, indicator: TabIndicator | None = None) -> None:
    url = (
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream"
        f"?optimize_streaming_latency=3&output_format=mp3_44100_128"
    )
    body = json.dumps({
        "text": text,
        "model_id": model,
        "voice_settings": {
            "stability": 0.45,
            "similarity_boost": 0.85,
            "style": 0.30,
            "use_speaker_boost": True,
        },
    }).encode()
    req = Request(url, data=body, headers={
        "xi-api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
    })

    ffplay = subprocess.Popen(
        ["ffplay", "-autoexit", "-nodisp", "-loglevel", "quiet", "-"],
        stdin=subprocess.PIPE,
    )
    write_pid_file(mode, os.getpid(), ffplay.pid)
    if indicator is not None:
        indicator.start()

    def handle_term(signum, frame):
        log("signal received, terminating playback")
        # Restore the tab title FIRST — fast, no thread wait. Even if we die
        # before anything else, the title won't be stuck.
        if indicator is not None:
            indicator.force_restore()
        try:
            ffplay.terminate()
        except Exception:
            pass
        if indicator is not None:
            indicator.stop()
        cleanup_pid_file()
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_term)
    signal.signal(signal.SIGINT, handle_term)

    try:
        with urlopen(req, timeout=30) as resp:
            while True:
                chunk = resp.read(4096)
                if not chunk:
                    break
                try:
                    if ffplay.stdin is None:
                        break
                    ffplay.stdin.write(chunk)
                    ffplay.stdin.flush()
                except BrokenPipeError:
                    break
    except HTTPError as e:
        log(f"http {e.code}: {e.read()[:200]!r}")
    except URLError as e:
        log(f"network error: {e}")
    finally:
        try:
            if ffplay.stdin is not None:
                ffplay.stdin.close()
        except Exception:
            pass
        ffplay.wait()
        if indicator is not None:
            indicator.stop()
        cleanup_pid_file()


def parse_args(argv: list[str]) -> tuple[str, str | None, str | None, str]:
    """Return (mode, explicit_text, tty_path, label)."""
    mode = MODE_FULL
    text: str | None = None
    tty_path: str | None = None
    label = ""
    read_stdin = False
    i = 1
    while i < len(argv):
        a = argv[i]
        if a.startswith("--mode="):
            mode = a.split("=", 1)[1]
        elif a == "--text" and i + 1 < len(argv):
            text = argv[i + 1]
            i += 1
        elif a == "--tty" and i + 1 < len(argv):
            tty_path = argv[i + 1]
            i += 1
        elif a == "--label" and i + 1 < len(argv):
            label = argv[i + 1]
            i += 1
        elif a == "--stdin":
            read_stdin = True
        i += 1
    if read_stdin:
        mode = MODE_SAY
        text = sys.stdin.read()
    return mode, text, tty_path, label


class TabIndicator:
    """Pulses a title onto the given tty while playback runs.
    Format: 🔊 Bella — <label>
    Uses xterm push/pop title stack to restore the tab's previous title."""

    FRAMES = ["🔊", "🔉", "🔈", "🔉"]

    def __init__(self, tty_path: str | None, label: str = ""):
        self.tty_path = tty_path if tty_path and os.path.exists(tty_path) else None
        self.label = label
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        self._pushed = False

    def _write(self, seq: str) -> None:
        if not self.tty_path:
            return
        try:
            with open(self.tty_path, "w") as f:
                f.write(seq)
                f.flush()
        except OSError:
            pass

    def _loop(self) -> None:
        i = 0
        suffix = f" — {self.label}" if self.label else ""
        while not self._stop.is_set():
            frame = self.FRAMES[i % len(self.FRAMES)]
            self._write(f"\033]0;{frame} Bella{suffix}\007")
            i += 1
            if self._stop.wait(0.5):
                break

    def start(self) -> None:
        if not self.tty_path:
            return
        # Push current title BEFORE the thread starts, so we know _pushed is
        # true whether or not the thread has spun up yet.
        self._write("\033[22;0t")
        self._pushed = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def force_restore(self) -> None:
        """Pop the title stack immediately — safe to call from signal handlers,
        idempotent, doesn't wait on the animation thread."""
        if not self.tty_path or not self._pushed:
            return
        self._write("\033[23;0t")
        self._pushed = False

    def stop(self) -> None:
        if not self.tty_path:
            return
        self._stop.set()
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=0.5)
        self.force_restore()


def main() -> int:
    api_key = get_api_key()
    if not api_key:
        log("no ELEVENLABS_API_KEY in keychain — run bella-setup.sh first")
        return 2

    cfg = load_config()
    voice_id = cfg.get("voice_id", DEFAULT_VOICE_ID)
    model = cfg.get("model_id", DEFAULT_MODEL)
    char_cap = int(cfg.get("char_cap", 5000))

    mode, explicit_text, tty_path, label = parse_args(sys.argv)

    if mode == MODE_SAY:
        if not explicit_text or not explicit_text.strip():
            log("say mode but no text provided")
            return 6
        text = explicit_text.strip()
        # Light clean — strip code fences but keep the prose intent
        text = clean_for_speech(text)
        if not text:
            log("say text empty after cleaning")
            return 7
    else:
        jsonl = find_current_jsonl()
        if not jsonl:
            log("no JSONL transcripts found under ~/.claude/projects")
            return 3
        raw = extract_latest_assistant_text(jsonl)
        if not raw:
            log(f"no assistant message in {jsonl}")
            return 4
        text = clean_for_speech(raw)
        if not text:
            log("cleaned text empty (probably code-only response)")
            return 5
        if mode == MODE_RECAP:
            text = extract_recap(text)

    if len(text) > char_cap:
        text = text[:char_cap].rsplit(". ", 1)[0] + "."

    log(f"mode={mode} speaking {len(text)} chars tty={tty_path} label={label!r}")
    indicator = TabIndicator(tty_path, label) if tty_path else None
    stream_tts(text, voice_id, model, api_key, mode=mode, indicator=indicator)
    return 0


if __name__ == "__main__":
    sys.exit(main())
