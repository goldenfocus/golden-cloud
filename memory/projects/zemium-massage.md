---
name: zemium-massage (first vertical)
description: Self-serve service-business platform; massage vertical at massage.zemium.net; KV-backed tenants, /start onboarding form, akashik event log; canonical brain-dump in ~/zemium-massage/HANDOVER.md
type: project
---

`~/zemium-massage/` — the first Zemium vertical, forked from plomberiepsf. Live at https://massage.zemium.net/. Cloudflare Pages + Astro 6 (static for marketing) + CF Pages Functions (dynamic tenant routes) + KV-backed tenant store + R2 uploads + Twilio + Resend.

**Why:** Beachhead for the Zemium product — a "Shopify for service businesses" packaged as a turnkey product for non-tech owners (design + hosting + booking + dossiers + SMS/email + AI atelier). Vertical-first GTM: massage → plumber → electrician → dentist → restos. JR will dogfood the same infra at mirweb.com for his own sites.

**How to apply:** When any Zemium / massage.zemium.net / onboarding / akashik / multi-tenant / mirweb question comes up, the **canonical source of truth is `~/zemium-massage/HANDOVER.md`**. Read that file first — it covers stack, repo layout, KV schema, ops cheatsheet, known issues, P0/P1/P2 roadmap. This memory entry is just a pointer; details rot too fast to mirror here.

**Current snapshot (2026-04-29):** Production end-to-end works. /start onboarding form → /api/onboard writes tenant to KV → site live in seconds. Bookings persist as Ships, fire SMS+email. Custom domains zemium.net + massage.zemium.net attached (wildcard *.zemium.net not attached — CF dashboard rejects wildcards, JR didn't want to deal with API tokens). Two tenants in KV: `serenite` (seed, placeholder phone) and `lotus` (test, placeholder phone). Next P0: onboard a real Lachine massage BM, add `tenant-ships:<slug>` listing index, BM admin lead-status writes.

**Distinct from `zemium.md`** (the original mobile app concept with Chat/Bookings/Signals pillars) — zemium-massage is the FIRST consumer of those pillars, in web form, vertical-targeted.
