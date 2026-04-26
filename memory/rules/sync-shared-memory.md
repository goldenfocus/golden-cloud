---
name: Rule — sync shared memory (write to golden-cloud + git push)
description: Cross-AI/cross-project facts go in ~/golden-cloud/memory/ and get committed+pushed; per-laptop facts stay local
type: project
---

**Rule:** When you learn something worth remembering, decide where it lives:

| The fact is about… | Lives in… |
|---|---|
| A person in Golden Focus (preferences, role, style) | `~/golden-cloud/memory/users/<name>.md` |
| A project shared across laptops/AIs (zemium, p69, lamtl, …) | `~/golden-cloud/memory/projects/<name>.md` |
| A binding rule for any AI in any Golden Focus project | `~/golden-cloud/memory/rules/<name>.md` |
| Repo map, infra, operating manuals, external resources | `~/golden-cloud/memory/reference/<name>.md` |
| One-laptop-only state (e.g., a path that only exists on this machine) | `~/.claude/projects/<slug>/memory/<name>.md` (local-only) |
| In-flight work, this-session-only context | tasks / plans, **not** memory |

**Always commit + push after writing to golden-cloud.** A memory that exists only locally on one laptop is worthless to the other AIs/people. The flow:

```
# write your memory file under ~/golden-cloud/memory/<subdir>/<name>.md
# update ~/golden-cloud/memory/MEMORY.md to index it
cd ~/golden-cloud
git add memory/
git commit -m "gc-memory: <one-line summary>"
git push
```

**After adding a new shared file, run** `~/golden-cloud/laptop/gc-memory-sync.sh` so each project's local `MEMORY.md` regenerates its `## Shared` section. (The symlink to `shared/` is already in place, but the index needs a refresh to surface the new entry to Claude Code's auto-loader.)

**Don't write secrets into memory files.** Memory is plain markdown, public-readable to anyone with repo access. See `no-plaintext-secrets.md`.
