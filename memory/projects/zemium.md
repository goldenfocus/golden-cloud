---
name: zemium — overview
description: Mobile app for service providers; three atomic pillars (Chat/Bookings/Signals); first product built from "golden blocks"; Slice A (Signals API) is currently in extraction from p69 worktree
type: project
---

zemium is a mobile app for service providers (initial vertical: wellness/spa). Placeholder live at https://zemium.app announces three pillars:

1. **Chat** — every client conversation kept, searchable, translated. Gated to verified/confirmed buyers only.
2. **Bookings** — real-time availability, tap-to-confirm.
3. **Signals** — push + SMS + email notifications, "right channel right moment."

**Why:** yan (dad) framed it as the very first experiment built **"from golden blocks"** — meaning the first product where reusable modules from `~/golden-cloud/blocks/` are the primary building material. Design constraint: must pass app-store rules → atomic products only, no kitchen-sink PMS bloat.

**How to apply:** When proposing scope, default to atomic over comprehensive. Notifications-that-actually-fire is the explicit wedge ("notifications king", "zero time waiters"). Push back on feature creep that mirrors ClinicSense breadth.

## Customers identified

- **p69** (lamtl provider tenant) — first zemium client.
- A spa 3 blocks from JR — currently pays ~$100/mo for ClinicSense-class software with no SMS; identified as second target.
- ClinicSense (https://www.clinicsense.com) is the comp — kitchen-sink wellness PMS. Wedge against them on focus, mobile-first, notifications that actually fire.

## Stack signals so far

- OneSignal (key in `~/zemium/.env.local`). Launch year per site: 2026 (MMXXVI). Tagline: "Quiet launch."
- Supabase migrations are the persistence layer (per p69 worktree).

## Slice A (Signals as a flexible notification API/SDK) — IN EXTRACTION

Confirmed direction (2026-04-23, JR): **NOT** a mobile app first. **NOT** greenfield design either. Strategy:

- OneSignal wrapped behind a provider-adapter seam ("WebPushAdapter") so providers swap by changing one adapter, not callers.
- Surface is "super flex front/back/fullstack API for whoever needs this" — first consumers are p69 + lamtl, designed for additional apps to plug in later.
- Goal: nail notification reliability for p69/lamtl at ~80% before adding more pillars. Becomes the first reusable golden block.
- Mobile app UI is downstream of the API working in production.

**Prior work — Slice A is half-shipped already, trapped inside p69's worktree:**

- Branch: `worktree-zemium-onesignal-adapter`
- Path: `/Users/theoutsider/p69/.claude/worktrees/zemium-onesignal-adapter`
- Head: `0aedf6427` ("OneSignal v2 auth model — org-key mints app-scoped tokens"), as of 2026-04-23
- Scope: ~1670 LOC, 27 files, includes:
  - `src/lib/zemium/signals/adapters/{types,index,webpush-onesignal,webpush-vapid}.ts` + tests
  - `src/lib/zemium-client/{config,subscribe,subscribe-onesignal,subscribe-vapid}.ts` + tests
  - `src/lib/push-tenant-resolver.ts` (multi-tenant routing, 116 LOC)
  - `src/app/api/zemium/onesignal-webhook/route.ts` + tests (delivery receipts)
  - `src/app/api/zemium/tenant-config/route.ts` (runtime tenant config)
  - `scripts/onboard-tenant.ts` (programmatic tenant provisioning, 201 LOC)
  - `supabase/migrations/20260420142323_zemium_tenants.sql` (per-tenant OneSignal credentials)
  - `supabase/migrations/20260420121117_push_subscriptions_add_provider.sql`
  - `OneSignalBootstrap.tsx` (conditional SDK mount)

**Open question (TBD next session):** where does the extracted block live?
- (a) `~/zemium/packages/signals/` — product repo
- (b) `~/golden-cloud/blocks/zemium-signals/` — canonical golden block
- (c) Both — block in golden-cloud (reusable infra), product shell in `~/zemium/`. Current lean: (c).
