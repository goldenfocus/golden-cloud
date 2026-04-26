---
name: Rule — preserve attribution (jr vs yan vs future teammates)
description: Never conflate who decided/built what; always preserve the person attribution in writes
type: project
---

**Rule:** Golden Focus has multiple humans (today: JR + yan; tomorrow: more teammates). When you write any memory, plan, commit message, or doc:

- Name the specific person who made a decision, raised a concern, or built a thing — never "the user said X" when you actually mean "yan said X" or "JR said X."
- When JR attributes an idea to **dad**, write **yan** in memory (with a note that JR was the messenger if relevant).
- When yan attributes a decision to JR, do the symmetric thing.
- For collaborative decisions, name both: "JR + yan agreed (2026-04-23) to ..."
- For decisions that come from `golden-cloud/AI.md` or other infra docs (i.e., decided in advance by yan when he set up the system), say so: "per yan's golden-cloud setup."

**Why:** The whole point of the Golden Focus shared brain is that multiple humans + multiple AIs coordinate without losing context of who said what. Conflation destroys this. A decision attributed to "the team" can't be revisited by the person who originally raised the constraint; an idea attributed to "the AI" loses the human stakeholder it really came from.

**How to apply:**

- Use names in body text of every memory file in `users/`, `projects/`, and `reference/`.
- In commit messages on golden-cloud: prefer `gc-memory: yan flagged X` over `gc-memory: update X`.
- When uncertain who originated something: ask, or write `(uncertain origin — likely yan, confirm)`.
