---
name: golden-design-ritual
description: Use when the user wants to explore, prototype, or redesign a UI/UX surface and see it live — generates 2-4 distinct, PLAYABLE frontend prototypes and publishes them to the project's own site at /designs/<slug> for instant shareable preview. Triggers: "design ritual", "spin up designs", "prototype the X screen", "redesign the X", "show me design options live".
---

# Golden Design Ritual

Turn a "redesign X" request into several playable, production-grade prototypes
published LIVE to the project's site at `/designs/<slug>`. Previews are instantly
shareable, permanent, and real code — the winner can be promoted into the app fast.

## Config

Read `./.claude/design-ritual.json` from the repo root. Required keys:
`site`, `publisher`, `r2_bucket`, `designs_prefix`. If the file is MISSING, ask the
user for the values once, write the file, then continue. Never guess the bucket/site.

Only `publisher: "r2-worker"` is supported in v1 (upload to R2, served by the
project's Worker at `/designs/*`).

## Ritual

1. **Frame** — ask, tightly: which surface? vibe / references? must-keeps?
   how many directions (default 3)? One short volley, not an interrogation.
2. **Generate** — invoke the `frontend-design` skill to produce N DISTINCT
   directions. Each prototype MUST be a single self-contained `.html` file with
   inline CSS/JS and REAL interactions (e.g. a Wordle board you can type into).
   Write them to `/tmp/<slug>.html`. Choose short kebab-case slugs.
3. **Publish** — for each prototype, run:
   `~/.claude/skills/golden-design-ritual/publish.sh /tmp/<slug>.html <slug> "<Title>" exploring`
   Run from the repo root so it finds `.claude/design-ritual.json`.
4. **Report** — give the user the live `https://<site>/designs/<slug>` links and
   the gallery link `https://<site>/designs/`. If any slug failed to publish, say
   which — never imply a partial gallery is complete.

## Promotion

When the user picks a winner, lifting its HTML/CSS/JS into the live app is a normal
dev task (not automated here). Optionally re-publish that slug with status `shipped`
to badge it in the gallery.

## Notes

- Prototypes never go to git — they live in R2 forever. Only the config file is
  committed.
- Credentials come from wrangler OAuth + golden-cloud R2 keys; never prompt the
  user to paste secrets.
