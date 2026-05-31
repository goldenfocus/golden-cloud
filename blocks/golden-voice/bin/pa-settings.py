#!/usr/bin/env python3
# bin/pa-settings.py — read/write golden-voice listen-mode settings.
import json, os, sys

PATH = os.path.expanduser("~/.claude/local-tts/play-audio.json")
DEFAULTS = {
    "auto": False,
    "defaultDepth": "full",      # full | medium | recap (only full implemented now)
    "voice": "me",
    "speed": 1.0,
    "fxPreset": "clean",         # clean | warm | reverb | echo
    "maxCharsBeforeCondense": 1200,
    "announceProject": True,
    "summarizer": "none",        # later: "ollama:llama3.2:3b"
}

def load():
    d = dict(DEFAULTS)
    if os.path.exists(PATH):
        try:
            d.update(json.load(open(PATH)))
        except Exception:
            pass
    return d

def _coerce(v):
    if isinstance(v, str):
        if v.lower() in ("true", "false"):
            return v.lower() == "true"
        try: return int(v)
        except ValueError:
            try: return float(v)
            except ValueError: return v
    return v

def set_kv(key, value):
    d = load()
    d[key] = _coerce(value)
    os.makedirs(os.path.dirname(PATH), exist_ok=True)
    json.dump(d, open(PATH, "w"), indent=2)
    return d[key]

def main(argv):
    if not argv or argv == ["get"]:
        print(json.dumps(load(), indent=2)); return
    if argv[0] == "get":
        print(load().get(argv[1], "")); return
    if argv[0] == "set":
        print(f"{argv[1]}={set_kv(argv[1], argv[2])}"); return
    print("usage: pa-settings.py [get [key] | set <key> <value>]", file=sys.stderr); sys.exit(2)

if __name__ == "__main__":
    main(sys.argv[1:])
