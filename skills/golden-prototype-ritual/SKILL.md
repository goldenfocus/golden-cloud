---
name: golden-prototype-ritual
description: Stage 2 of the design flow — after a golden-design-ritual direction is APPROVED, build it as a living prototype in the real codebase (real components, real data, real surfaces) behind a gate, deployed to a preview URL for phone-in-hand sign-off. Triggers: "prototype ritual", "spin up the prototype", "make it real", "golden prototype", or an approved design direction that needs to become code.
---

# Golden Prototype Ritual

The design ritual (`golden-design-ritual`) explores with standalone HTML — fast,
disposable, zero dependencies. This ritual is what happens **after approval**: the
winning direction is rebuilt as REAL code in the actual repo, so "it works" means
it works — same components, same data shapes, same modal/stacking/i18n/CDN reality
as production. When it graduates, shipping is removing the gate, not rewriting.

> Origin (2026-07-04): the blur tool "worked on /designs" but prod broke twice —
> a bare Cloudflare Images id fed to the editor (black crop) and a stacking-context
> trap the standalone mockup could never exhibit. Prototypes that share zero code
> with the product prove visual direction only. This ritual closes that gap.

## Non-negotiables

1. **Same codebase.** The prototype is a branch in the product repo using the
   real design-system primitives (`src/components/ui/`), real routes or the real
   surface, real hooks/services. No parallel HTML, no copied CSS.
2. **Prod-shaped data.** Load the same fields production loads (bare CF Images
   ids, real locales, empty states, long names). If the surface reads
   `user_profiles`, the prototype reads `user_profiles`.
3. **Real surfaces, plural.** Mount it everywhere it will actually live (e.g. a
   shared modal must be exercised from cockpit AND profile AND gallery), on a
   phone viewport, before sign-off.
4. **Gated, not hidden-by-obscurity.** Behind a feature flag, an admin/god-mode
   gate, or a preview-only route — never indexable, never reachable by customers.

## Ritual

1. **Frame** — confirm the approved direction (link the winning
   `/designs/<slug>`), the target surface(s), and the gate mechanism. One volley.
2. **Worktree** — `git worktree add .worktrees/proto-<slug> -b proto/<slug> origin/main`.
3. **Build** — implement with real primitives on the real surface(s) behind the
   gate. i18n keys in all 12 locales from the start (placeholder-free). Tests
   alongside, per repo rules.
4. **Deploy preview** — push the branch; Vercel builds a preview URL. Never
   demo from localhost.
5. **Verify like prod** — run `premium-ux-auditor` on the surface, plus a
   Playwright pass on the preview: mobile viewport, real data, tap the actual
   flow end-to-end, screenshot evidence. Check the incident classics: bare-id
   media fields, overlay stacking above Radix dialogs (OverlayPortal), input
   zoom, dvh, touch scroll.
6. **Sign-off** — send the preview URL + 3-step phone test to the user. Approval
   here means the CODE is approved, not just the look.
7. **Graduate** — remove/flip the gate on the same branch, then the normal push
   gauntlet (build, i18n, pill, zoom, reviewers, smoke). QA is NOT skipped —
   the point is that it stops finding surprises.

## Relationship to golden-design-ritual

| | Design ritual (stage 1) | Prototype ritual (stage 2) |
|---|---|---|
| Purpose | explore directions | prove the winner integrates |
| Artifact | standalone HTML in R2 | branch in the product repo |
| Data | fake | prod-shaped |
| Lives at | `/designs/<slug>` | Vercel preview / gated route |
| On approval | pick a winner | flip the gate = shipped |

Skipping stage 1 is fine for small surfaces with an obvious direction; skipping
stage 2 is how "it worked on the mockup" ships broken.
