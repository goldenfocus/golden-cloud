#!/usr/bin/env python3
# chunk_text.py — split text into TTS-safe chunks (XTTS-v2 limit ~250 chars/call).
# Splits on sentence boundaries; further splits over-long sentences on clause
# punctuation, then on whitespace as a last resort. Prints one chunk per line
# (internal newlines collapsed to spaces). Reads argv[1] or stdin.
import re, sys

MAX = int(__import__("os").environ.get("GV_CHUNK_MAX", "230"))

def _hard_split(s, mx):
    # split a too-long fragment on clause punctuation, then on spaces
    out, buf = [], ""
    for piece in re.split(r"(?<=[,;:—-])\s+", s):
        if len(buf) + len(piece) + 1 <= mx:
            buf = f"{buf} {piece}".strip()
        else:
            if buf:
                out.append(buf)
            if len(piece) <= mx:
                buf = piece
            else:
                # brute split on words
                w = ""
                for word in piece.split():
                    if len(w) + len(word) + 1 <= mx:
                        w = f"{w} {word}".strip()
                    else:
                        if w:
                            out.append(w)
                        w = word
                buf = w
    if buf:
        out.append(buf)
    return out

def chunk(text, mx=MAX):
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return []
    sentences = re.split(r"(?<=[.!?])\s+", text)
    chunks, buf = [], ""
    for sent in sentences:
        if len(sent) > mx:
            if buf:
                chunks.append(buf); buf = ""
            chunks.extend(_hard_split(sent, mx))
        elif len(buf) + len(sent) + 1 <= mx:
            buf = f"{buf} {sent}".strip()
        else:
            if buf:
                chunks.append(buf)
            buf = sent
    if buf:
        chunks.append(buf)
    return chunks

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()
    for c in chunk(src):
        print(c)
