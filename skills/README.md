# Skills — shareable Claude Code skills

Claude Code skills anyone on the team (or any agent on any machine) can install.
Public like everything else in the cloud: free to use, fork, remix.

## Install

Copy (or symlink) a skill folder into your user skills directory:

```bash
cp -R ~/golden-cloud/skills/<skill-name> ~/.claude/skills/
```

Claude Code picks it up at the next session start. Skills here are the source of
truth — if you improve one locally, copy it back and push.

## The design flow pair

| Skill | Stage | What it does |
|---|---|---|
| [golden-design-ritual](golden-design-ritual/SKILL.md) | 1 — explore | Generates 2–4 distinct, playable standalone-HTML prototypes and publishes them live to the project's `/designs/<slug>` gallery for instant shareable preview. |
| [golden-prototype-ritual](golden-prototype-ritual/SKILL.md) | 2 — prove | Rebuilds the APPROVED direction in the real codebase — real components, real surfaces, prod-shaped data — behind a gate on a preview deploy, signed off phone-in-hand. Shipping = flipping the gate. |

Why two stages: standalone mockups are fast because they share zero code with the
product — which also means "the mockup works" proves visual direction only. Stage 2
walks the mockup→production gap with real data *before* anyone says "push, it's
working."

Per-project config: `golden-design-ritual` reads `.claude/design-ritual.json` in
the target repo (site, publisher, R2 bucket). `golden-prototype-ritual` needs no
config — it uses the repo's own primitives, preview deploys, and push gauntlet.
