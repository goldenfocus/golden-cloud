---
name: Golden Avatar block
description: Unified avatar+@username primitive for p69 + future goldenfocus consumers. One import, can never forget premium halo / banned / online / video avatar.
type: project
---

# Golden Avatar (`<GoldenAvatar>`)

Component name locked (2026-04-24, Zang): **golden-avatar** / `<GoldenAvatar>`. Not UserChip, not Sigil, not Medallion.

## Why
p69 has ~98 places hand-coding `/@${username}` links + ~50 files hand-rolling avatar rendering. Every new feature re-implements and forgets something (premium gold halo, banned fallback, `is_video_avatar` HLS autoplay, online green dot). Same DNA as BracketButton: one primitive, can't screw up.

## Surface
```tsx
<GoldenAvatar
  profile={p}
  size="xs|sm|md|lg"   // 20 / 28 / 36 / 48 — default sm
  showOnline            // opt-in, client-only shim
  linkOff               // for rows that are already a link
  compact               // avatar only, no @username text
  className=""
/>
```

## Field contract (query side)
```ts
export const GOLDEN_AVATAR_FIELDS = 'user_id, username, display_name, avatar_url, is_video_avatar, membership_type, account_status' as const
export type GoldenAvatarProfile = { ... }  // derived
```
Supabase `.select(GOLDEN_AVATAR_FIELDS)` → typed profile → drops straight into `<GoldenAvatar>`. Add a field once, updates every consumer.

## Rules baked in (canonical behavior mirrors `src/components/Chat/ChatBox/Messages/Message/index.tsx` ~L533-613)
- `account_status='banned'` → `<BannedAvatar>`, no link
- `account_status='deleted'` → ghost svg + `account_deleted` text, no link
- missing `username` → no link, fallback to `display_name` or `user_id` slice
- `is_video_avatar` → UserAvatar already handles HLS autoplay
- `membership_type='premium'` → gold halo via UserAvatar
- premium halo + online dot coexist without collision
- Link from `@/lib/i18n` (NEVER `next/link`)
- href = `/@${username}`

## Source primitives to study (don't dup, compose)
- `src/components/ui/UserAvatar.tsx` — avatar_url, is_video_avatar, premium halo, fallback initials (solid base)
- `src/components/BannedAvatar.tsx`
- `src/components/Chat/OnlineIndicator.tsx`
- `src/components/Chat/ChatBox/Messages/Message/index.tsx` L533-613 — canonical inline pattern to replace

## Architecture decision: client-only (Zang locked, 2026-04-30, pick A)
`UserAvatar` already ships `'use client'` (imports `hls.js` for video avatars), so `<GoldenAvatar>` inherits client by inheritance — no quick way around it. Splitting `UserAvatar` into a server shell + client `<VideoAvatarIsland>` was option B (~2× the work, would unlock RSC streaming across ~80 server pages). Zang picked A → ship client-only now, defer the split until the sweep is done and we have a real bundle-size readout. `showOnline` still gates the `useChatStore` import (only paid when `true`).

## Proof migration (first PR)
Branch: `feat/golden-avatar-block`. Migrate `src/app/admin/video-calls/page.tsx` (inline `<img>+<a>` in UserList ~L405-430 + @caller→@callee cell ~L270). Update queries in `aggregateByUser` + `fetchRecentCalls` to use `GOLDEN_AVATAR_FIELDS`. Screenshot before/after in PR body.

## Sibling-tab guardrail
Do NOT touch `src/components/GoldenFocus/*` or `supabase/functions/daily-call/*` — another Colony agent is live there (see commit 638f58ec9 surface).

## Sweep plan (post-proof)
Real win = sweeping all 98 `/@${username}` + 50 avatar sites. Name a codemod follow-up in the first PR body so the broom actually swings.

## Parking lot — NOT this scope
- **GoldenID** = separate product direction (cross-galaxy SSO, Screening Passport carrier, "Sign in with GoldenID" button for 3rd parties). GoldenAvatar becomes its visual render inside p69. Decided (Zang, 2026-04-24): stay focused on component first, revisit ID-as-product later.

## Style/brand hook
"Golden" prefix is intentional — this is the first p69→golden-blocks candidate for the avatar/identity slice. Neutral name, premium vibe, publishable as `@goldenfocus/avatar` or similar when extraction-ready.
