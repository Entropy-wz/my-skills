# Draft issues (Lane A — do not `gh issue create` until Lane B/C)

Copy into GitHub when leaving Lane A. Structural headers kept stable for work-lanes.

---

## Umbrella (optional)

**Title:** `feat(searxng-search): Phase 2 research quality`

```markdown
Why:
MVP SearXNG kit is on main. Heavier research needs excerpts, less upstream hammering, and clearer CN/rate-limit ops — still without paid search APIs.

What to build:
- Child issues for fetch, cache, and CN/ops playbook (see docs/design/2026-07-25-searxng-phase2.md)

Acceptance Criteria:
- [ ] Children filed and ordered (C → B → A recommended)
- [ ] Design doc linked from each child

Notes:
Design: docs/design/2026-07-25-searxng-phase2.md
```

---

## Child A — fetch

**Title:** `feat(searxng-search): fetch top-N page text for research`

```markdown
Why:
Snippets are too thin for case-study / report citation workflows.

What to build:
- tools/fetch helper + skill trigger for explicit deep/body requests
- trafilatura (or equivalent) with timeouts and batch continue-on-error

Acceptance Criteria:
- [ ] Top 3–5 URLs return excerpts with source URLs
- [ ] Per-URL timeout; one failure does not fail the batch
- [ ] README documents research/cite policy

Verification:
- Manual: search then fetch on 3 known URLs

Blocked by:
None (cache optional)

Notes:
Design: docs/design/2026-07-25-searxng-phase2.md §P2-A
```

---

## Child B — cache

**Title:** `feat(searxng-search): filesystem result cache with TTL`

```markdown
Why:
Repeated agent queries trigger upstream CAPTCHA/429; cache cuts load.

What to build:
- File cache under kit .cache/ (gitignored), TTL default 24h
- search.ps1 -NoCache / -Refresh
- Redis explicitly deferred

Acceptance Criteria:
- [ ] Identical query within TTL logs cache hit and skips SearXNG
- [ ] .cache gitignored
- [ ] Docs updated

Verification:
- Two identical searches; second is cache hit

Notes:
Design: docs/design/2026-07-25-searxng-phase2.md §P2-B
```

---

## Child C — CN / rate-limit ops

**Title:** `docs(searxng-search): CN recall and rate-limit playbook`

```markdown
Why:
Chinese queries and engine suspensions need visible ops guidance.

What to build:
- Surface unresponsive_engines in search output
- README section for CN opt-in engines + rate-limit steps
- Optional client min-interval

Acceptance Criteria:
- [ ] Partial failures list which engines failed
- [ ] README CN + rate-limit section present
- [ ] Defaults unchanged

Verification:
- Force a bad engine / inspect footer on limited run

Notes:
Design: docs/design/2026-07-25-searxng-phase2.md §P2-C
```

---

## Stand-alone — CI

**Title:** `ci: windows-latest smoke via check-layout.ps1`

```markdown
Why:
Install/layout regressions should fail PRs before merge, matching local gates.

What to build:
- .github/workflows/smoke.yml on push/PR to main
- windows-latest + pwsh running ./scripts/check-layout.ps1
  (includes smoke-install today — single step)

Acceptance Criteria:
- [ ] Workflow file on main
- [ ] Green run on main after merge
- [ ] No Docker/SearXNG in this workflow
- [ ] README notes CI smoke

Verification:
- Link first green Actions run
- Optional: draft PR that breaks SkillSources path → expect red

Notes:
Design: docs/design/2026-07-25-minimal-ci.md
```
