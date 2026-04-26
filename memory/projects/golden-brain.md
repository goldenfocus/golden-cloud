# Golden Brain — Empire Command Center

## What it is
The AI-operated second brain and command center for Yan's business empire. All ideas, projects, and automation status live in Linear. Every AI in the Golden Focus ecosystem must read from and write to it.

## Linear Workspace
- **URL:** https://linear.app/yanlovez
- **Team:** Yan Lovez (`YAN`, ID: `1cc5fdd1-586c-4d10-aec8-8241bc53574f`)
- **API Key:** stored in `~/golden-cloud/secrets/linear.env` as `LINEAR_API_KEY`
  - Also available in `~/.hermes/.env` on this laptop

## Projects
| Project | Purpose |
|---------|---------|
| 💡 Idea Vault | Raw ideas — captured automatically by AI before they get buried |
| 🏗️ p69 — Marketplace | p69.io adult services marketplace (Next.js 14 + Supabase + Vercel) |
| 🤖 MADAME — AI Salon Agent | AI front desk for LAMTL, autopost to escort sites via Playwright |
| 🏠 Real Estate | Room rentals, Kijiji automation, property listings |
| 🔮 Future Empires | Solid ideas not yet started — 80% baked, waiting for their moment |

## Labels
| Label | Meaning |
|-------|---------|
| 💡 Idea | Raw idea, not yet evaluated |
| 🚀 Active | Currently being worked on |
| 🏗️ Building | In active development |
| 🅿️ Parked | Paused — will return |
| 🤖 Automated | Running without human intervention |
| 💰 Revenue | Generating or directly tied to revenue |
| 🔥 Priority | Needs attention now |

## Rules for all AIs
1. **Capture every idea automatically.** If Yan mentions a business idea, product concept, or anything that sounds like a new venture — create a `💡 Idea` issue in Linear immediately. Don't wait to be asked.
2. **Document work as it happens.** When building something, update the corresponding Linear project with progress, blockers, decisions.
3. **Never let an idea die in conversation.** If it was said, it goes in the vault.
4. **Load the API key** from `~/golden-cloud/secrets/linear.env` via: `sops exec-env ~/golden-cloud/secrets/linear.env -- env | grep LINEAR`
   Or on this laptop from `~/.hermes/.env`: `export $(grep LINEAR_API_KEY ~/.hermes/.env | xargs)`

## Weekly Status
A cron job fires every Monday at 10am and sends Yan a voice briefing with full empire status via Telegram.

## API Quick Reference
```bash
# Base curl pattern
export LINEAR_API_KEY=<from secrets>
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { name } }"}' | python3 -m json.tool

# Create an idea issue
# teamId: 1cc5fdd1-586c-4d10-aec8-8241bc53574f
# Get label IDs first: { issueLabels { nodes { id name } } }
```
