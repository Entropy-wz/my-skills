# Draft issues — research case pipeline (Track B)

Lane A / brainstorming backlog. Do **not** `gh issue create` until the owner asks (usually Lane C).

---

## Umbrella

**Title:** `feat(research): case-study pipeline on SearXNG (search → fetch → cite)`

```markdown
Why:
Academic / competition work needs citable case cards and excerpt lists.
kits/searxng-search already provides local search, fetch, and cache without paid Search APIs.
Missing: an orchestration skill (or thin kit) that turns a topic into structured case cards.

What to build:
- Child issues for orchestration skill, output template aligned with report cards, citation list format
- Reuse kits/searxng-search tools only — no Brave/Tavily/SerpAPI requirement

Acceptance Criteria:
- [ ] Children filed and ordered
- [ ] Design linked from each child
- [ ] No paid search API in the default path

Notes:
Parent design: docs/design/2026-07-25-ship-gate-and-research-backlog.md
Depends on: searxng-search kit on main
```

---

## Child 1 — orchestrator skill

**Title:** `feat(skills): research-case-card orchestrates SearXNG search + fetch`

```markdown
Why:
Agents currently improvise multi-step search/fetch; output shape drifts across sessions.

What to build:
- skills/research-case-card (or agreed name): input topic + constraints → search → select URLs → fetch → emit case-card Markdown
- Explicit stop: no push/PR; cite sources; rate-limit aware (reuse search cache)

Acceptance Criteria:
- [ ] Skill documents the exact tool commands and output sections
- [ ] Runs against local SearXNG when up; clear error when down
- [ ] Top-N fetch with continue-on-error

Verification:
- One sample topic produces a card with ≥3 cited URLs

Blocked by:
None (SearXNG kit already shipped)

Notes:
Align optional sections with competition report cards when useful.
```

---

## Child 2 — citation list format

**Title:** `docs(research): citation list + case-card template`

```markdown
Why:
Stable paste targets for Feishu / report docs.

What to build:
- Template under docs/ or skill reference: case card fields + citation rows (URL, excerpt, retrieved date)
- Link from research-case-card skill

Acceptance Criteria:
- [ ] Template checked in
- [ ] Skill points at the template

Verification:
- Fill template once from a real SearXNG+fetch run
```
