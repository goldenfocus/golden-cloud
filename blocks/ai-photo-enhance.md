# AI Photo Enhance — Golden Block

> Take an existing profile photo and generate an enhanced version: better lighting, better composition, polished look. Uses img2img (image-to-image) AI — the result looks like the same person, not a random face.

## Use Cases

1. **Stale provider photos** — providers who haven't updated their photo in 6+ months get an in-chat offer: "We enhanced your photo — want to use it?"
2. **Low-quality uploads** — detect dark/blurry/poorly-lit photos on upload and offer an instant AI polish
3. **Profile upgrade nudge** — re-engagement hook for inactive providers, same interactive chat message pattern as avatar-reveal

## Technical Approach

- **img2img via fal.ai FLUX** — feed the existing Cloudflare image as reference, prompt with enhancement instructions
- **Prompt template**: "Same person, professional studio portrait, warm natural lighting, neutral background, high quality, sharp focus"
- **Strength parameter**: controls how much the AI changes (0.3 = subtle polish, 0.7 = significant restyle) — start conservative
- **Cost**: same as txt2img (~$0.003/image with Schnell)

## UX Pattern

Reuses the avatar-reveal interactive chat message (bracket buttons, inline in chat):
- Image shows enhanced version (large, tappable to expand)
- "Keep this look" / "Upload new" / "Try another" buttons
- Subtle "manage your photos" link

**Key difference from avatar-reveal**: the user already has a photo, so framing matters:
- Avatar reveal: "We made you a portrait" (gift)
- Photo enhance: "We think you'd look amazing with a little polish" (suggestion)
- Enhancement should feel like a compliment, not criticism

## Consent & Sensitivity

- NEVER auto-apply enhanced photos — always offer, never replace
- The enhanced version is a PREVIEW until the user accepts
- "Not for me" should be frictionless (unlike avatar-reveal where friction is OK)
- Consider opt-out: if someone declines once, don't offer again for 6 months

## Trigger Conditions

- Provider photo older than 6 months (check `avatar_url` change timestamp)
- Photo quality score below threshold (future: use Cloudflare AI or a simple brightness/sharpness check)
- Provider hasn't been active recently (re-engagement)

## Dependencies

- avatar-reveal chat message kind (build this first)
- fal.ai img2img endpoint
- Cloudflare Images (existing)

## Status

Idea — saved 2026-04-23. Build after avatar-reveal ships and validates.
