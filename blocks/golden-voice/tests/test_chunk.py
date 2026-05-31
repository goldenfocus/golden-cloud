# tests/test_chunk.py — chunker keeps every piece under the XTTS limit + loses no words.
import importlib.util, os
spec = importlib.util.spec_from_file_location("ck", os.path.expanduser("~/.claude/local-tts/bin/chunk_text.py"))
ck = importlib.util.module_from_spec(spec); spec.loader.exec_module(ck)

# short text → single chunk
assert ck.chunk("Hello there.") == ["Hello there."]

# long multi-sentence text → all chunks under limit, no words dropped
long = ("Shipped. All fourteen tasks done and the suite is green. " * 30).strip()
chunks = ck.chunk(long, mx=230)
assert all(len(c) <= 230 for c in chunks), [len(c) for c in chunks]
assert len(chunks) > 1
# word-preservation: same multiset of words in vs out
assert sorted(" ".join(chunks).split()) == sorted(long.split())

# a single sentence longer than the limit still gets broken up
one = "word " * 100  # 500 chars, no sentence breaks
oc = ck.chunk(one, mx=230)
assert all(len(c) <= 230 for c in oc)
assert len(oc) > 1

# empty / whitespace → no chunks
assert ck.chunk("   ") == []
print("OK")
