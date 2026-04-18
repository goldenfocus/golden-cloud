#!/bin/bash
# bella-setup.sh — one-shot setup.
# Stores ElevenLabs API key in macOS Keychain, looks up the Bella voice,
# writes ~/.claude/bella-tts/config.json.
set -euo pipefail

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "macOS only (uses Keychain + afplay/ffplay)." >&2
  exit 1
fi

for bin in jq curl ffplay; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "missing dependency: $bin" >&2
    echo "install with: brew install jq ffmpeg" >&2
    exit 1
  fi
done

API_KEY="${1:-}"
if [ -z "$API_KEY" ]; then
  read -rsp "ElevenLabs API key: " API_KEY
  echo
fi
[ -n "$API_KEY" ] || { echo "no key provided"; exit 1; }

security add-generic-password -a "$USER" -s "ELEVENLABS_API_KEY" -w "$API_KEY" -U
echo "✓ key stored in Keychain"

VOICE_ID=$(curl -s -H "xi-api-key: $API_KEY" "https://api.elevenlabs.io/v1/voices" \
  | jq -r '.voices[]? | select(.name | test("bella"; "i")) | .voice_id' | head -1)
if [ -z "$VOICE_ID" ]; then
  VOICE_ID="EXAVITQu4vr4xnSDxMaA"
  echo "! no Bella on account — falling back to canonical voice $VOICE_ID"
else
  echo "✓ Bella voice_id: $VOICE_ID"
fi

CONFIG_DIR="$HOME/.claude/bella-tts"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config.json" <<JSON
{
  "voice_id": "$VOICE_ID",
  "model_id": "eleven_turbo_v2_5",
  "char_cap": 5000
}
JSON
echo "✓ config at $CONFIG_DIR/config.json"

echo
echo "testing voice with a short clip..."
/usr/bin/python3 - "$VOICE_ID" "$API_KEY" <<'PY'
import json, subprocess, sys
from urllib.request import Request, urlopen
voice_id, api_key = sys.argv[1], sys.argv[2]
url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream?optimize_streaming_latency=3"
body = json.dumps({"text":"Bella here. Ready when you are.","model_id":"eleven_turbo_v2_5"}).encode()
req = Request(url, data=body, headers={"xi-api-key": api_key,"Content-Type":"application/json","Accept":"audio/mpeg"})
p = subprocess.Popen(["ffplay","-autoexit","-nodisp","-loglevel","quiet","-"], stdin=subprocess.PIPE)
with urlopen(req, timeout=20) as r:
    while True:
        c = r.read(4096)
        if not c: break
        p.stdin.write(c); p.stdin.flush()
p.stdin.close(); p.wait()
PY

echo "✓ done. now wire the hotkey (see instructions)."
