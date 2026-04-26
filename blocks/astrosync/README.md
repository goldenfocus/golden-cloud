# AstroSync — Golden Block 13

> Adaptive product layer that tunes UI tone, pacing, and content surfacing to user energy state.
> Ancient pattern recognition over A/B testing.

## What it does

AstroSync reads a user's current energy state from behavioral signals (and optionally birth data)
and adjusts the product experience to meet them where they are.

**High-agency / building energy** → full power mode (dense info, quick actions, no hand-holding)
**Calm / receptive energy** → gentle mode (more whitespace, slower pacing, softer CTAs)
**Creative energy** → discovery mode (surface new things, unexpected connections)
**Social energy** → community mode (highlight other users, shared activity, conversations)

## Signals (no birth data required)

- Time of day + day of week
- Session length and interaction cadence
- Scroll speed, tap frequency, dwell time
- Recent actions (building vs browsing vs connecting)
- Explicit mood (optional "how are you feeling?" prompt)

## Optional: Astrological layer

If user shares birth date (opt-in, private):
- Current planetary transits → energy forecast
- Moon phase → collective mood overlay
- Personal chart → long-term affinity mapping

## Block interface

```typescript
export interface AstroSyncProfile {
  energyState: 'building' | 'calm' | 'creative' | 'social' | 'unknown'
  intensity: number // 0-1
  suggestedMode: 'power' | 'gentle' | 'discovery' | 'community'
  confidence: number // 0-1
}

export interface AstroSyncAdapter {
  getProfile(userId: string, signals: BehavioralSignals): Promise<AstroSyncProfile>
}
```

## Status

- [ ] Behavioral signal collector
- [ ] Energy state classifier
- [ ] Product mode adapter interface
- [ ] Optional astrology layer
- [ ] p69 integration (provider dashboard adapts to salon energy)
- [ ] Zemium integration
