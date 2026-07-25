# Draft issues — research case pipeline (Track B)

**Live tracker (created Lane C 2026-07-25) — do not recreate:**

| Role | Issue |
| --- | --- |
| Umbrella | https://github.com/Entropy-wz/my-skills/issues/14 |
| Child — orchestrator | https://github.com/Entropy-wz/my-skills/issues/15 |
| Child — template | https://github.com/Entropy-wz/my-skills/issues/16 |

Full design (Lane A): [`docs/design/2026-07-25-research-case-pipeline.md`](../2026-07-25-research-case-pipeline.md)

Bodies below are the text used when filing; keep for archaeology.

---

## Umbrella → #14

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
Parent design: docs/design/2026-07-25-research-case-pipeline.md
Depends on: searxng-search kit on main
```

---

## Child 1 → #15

**Title:** `feat(skills): research-case-card orchestrates SearXNG search + fetch`

(see design §Skill behavior)

---

## Child 2 → #16

**Title:** `docs(research): citation list + case-card template`

(see design §Output contract)
