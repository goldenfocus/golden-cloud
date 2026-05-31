#!/usr/bin/env python3
# bin/tts_daemon.py — resident XTTS-v2 synth server. Model loaded ONCE.
# POST /synth  body: {"text": "...", "speaker_wavs": ["/a.wav", ...], "language": "en", "out": "/path.wav"}
# GET  /health -> 200 "ok" once the model is loaded.
import json, os, sys, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST, PORT = "127.0.0.1", 5111
os.environ.setdefault("COQUI_TOS_AGREED", "1")

print("[tts-daemon] loading XTTS-v2 (first run downloads ~1.8GB)…", flush=True)
from TTS.api import TTS  # noqa: E402
_tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
print(f"[tts-daemon] model ready on {HOST}:{PORT}", flush=True)

_synth_lock = threading.Lock()

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
        else:
            self.send_response(404); self.end_headers()
    def do_POST(self):
        if self.path != "/synth":
            self.send_response(404); self.end_headers(); return
        try:
            n = int(self.headers.get("Content-Length", 0))
            req = json.loads(self.rfile.read(n) or b"{}")
        except (ValueError, json.JSONDecodeError):
            self.send_response(400); self.end_headers(); self.wfile.write(b"bad JSON body"); return
        text = (req.get("text") or "").strip()
        spk = req.get("speaker_wavs") or []
        lang = req.get("language", "en")
        out = req.get("out")
        if not text or not spk or not out:
            self.send_response(400); self.end_headers(); self.wfile.write(b"need text+speaker_wavs+out"); return
        try:
            with _synth_lock:
                _tts.tts_to_file(text=text, speaker_wav=spk, language=lang, file_path=out)
            self.send_response(200); self.end_headers(); self.wfile.write(out.encode())
        except Exception as e:
            self.send_response(500); self.end_headers(); self.wfile.write(str(e).encode())

if __name__ == "__main__":
    ThreadingHTTPServer((HOST, PORT), H).serve_forever()
