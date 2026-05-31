#!/usr/bin/env python3
# bin/strip_prose.py — reduce markdown / assistant output to clean spoken prose.
import re, sys

def strip_prose(text: str) -> str:
    # fenced code blocks ```...```
    text = re.sub(r"```.*?```", " ", text, flags=re.DOTALL)
    # drop indented (4-space / tab) code lines
    text = "\n".join(l for l in text.splitlines() if not re.match(r"^( {4,}|\t)", l))
    # images ![alt](url) -> alt   (before links)
    text = re.sub(r"!\[([^\]]*)\]\([^)]*\)", r"\1", text)
    # links [text](url) -> text
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    # bare URLs dropped
    text = re.sub(r"https?://\S+", " ", text)
    # standalone file paths (token containing / and a .ext) dropped
    text = re.sub(r"\b[\w.\-/]*/[\w.\-/]+\.\w+", " ", text)
    # inline code -> inner text
    text = re.sub(r"`([^`]*)`", r"\1", text)
    # line-start markers: headings, blockquote, list bullets, ordered list
    text = re.sub(r"^\s{0,3}(#{1,6}\s+|>\s+|[-*+]\s+|\d+\.\s+)", "", text, flags=re.MULTILINE)
    # emphasis markers
    text = re.sub(r"(\*\*|__|~~|\*|_)", "", text)
    # table pipes -> space
    text = text.replace("|", " ")
    # collapse spaces and blank lines
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" *\n *", "\n", text)
    text = re.sub(r"\n{2,}", "\n", text)
    return text.strip()

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()
    sys.stdout.write(strip_prose(src))
