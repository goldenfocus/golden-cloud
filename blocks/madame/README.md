# 🎩 MADAME — Golden Block

> Auto-posting engine for classified ad platforms. App-agnostic. Plug into p69, Zemium, or any future app.

## What it does

MADAME is a headless classified-ad automation engine. Given credentials for a platform (escorteintime.com, Leolist, Kijiji, etc.), it:

1. **Toggles online presence** on a random interval (15–30 min) to stay on top of listings
2. **Logs every event** to a DB table (`madame_posting_events`)
3. **Respects pause/resume** per tenant per platform
4. **Stores encrypted credentials** per tenant in DB
5. **Exposes a REST API** any frontend can consume (status, events, pause, manual trigger)

## Architecture — app-agnostic

```
golden-cloud/blocks/madame/
  src/
    core/
      escorteintime.ts      ← platform adapter (pure, no DB)
      leolist.ts            ← (coming)
      kijiji.ts             ← (coming)
      types.ts              ← MadameAdapter interface
    engine/
      logger.ts             ← writeEvent(), updateConfig()
      scheduler.ts          ← randomInterval(15, 30) loop
      credentials.ts        ← AES-256-GCM encrypt/decrypt
    api/
      status.ts             ← GET /madame/[platform]/status
      toggle.ts             ← POST /madame/[platform]/toggle
      pause.ts              ← POST /madame/[platform]/pause
      events.ts             ← GET /madame/[platform]/events
  migrations/
    001_madame_tables.sql   ← portable SQL, works in any Supabase project
  ui/
    MadameCard.tsx          ← drop-in React component (shadcn/tailwind)
    MadameClient.tsx        ← full page view
```

## Adapter interface

```typescript
export interface MadameAdapter {
  platform: string                           // e.g. 'escorteintime.com'
  toggleOnline(credentials: Credentials): Promise<ToggleResult>
  getStatus(credentials: Credentials): Promise<PlatformStatus>
}
```

Adding a new platform = implement MadameAdapter. Zero changes to engine.

## How to consume in p69

```typescript
// src/lib/madame/index.ts
import { MadameEngine } from '@golden/madame'
import { EscorteintimeAdapter } from '@golden/madame/adapters/escorteintime'

export const madame = new MadameEngine({
  adapter: new EscorteintimeAdapter(),
  supabase: serverClient,
  encryptionKey: process.env.MADAME_SECRET!,
})
```

## How to consume in Zemium

Exact same import. Different `supabase` client, same schema (migrations are portable).

## DB tables (portable)

`madame_posting_events` — event ledger (one row per toggle/error/skip)
`madame_platform_config` — per-tenant config (is_active, encrypted creds, last_event)

RLS: tenant admins only. Works in any Supabase project.

## Status

- [x] escorteintime.com adapter (existing, needs refactor to adapter interface)
- [ ] Leolist adapter
- [ ] Kijiji adapter
- [ ] MadameCard UI component
- [ ] Full golden block extraction (currently embedded in p69)
