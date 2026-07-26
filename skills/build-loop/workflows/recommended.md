# Recommended workflows

Menu of skill chains for this toolkit. Invoked via the thin `build-loop` entry
(or read directly). **This file does not implement anything** — it only recommends
which skills to run next.

## Shared discipline (from former build-loop)

- **Bounded fix retries:** when fixing failing tests/gates, retry at most **3** times;
  then stop, report failures + hypotheses, and ask. No infinite fix loops.
- **No silent ship:** push / issues / PRs only via `work-lanes` Lane C (prefer
  `/ship-gate` first).
- **Evidence before "done":** paste green test/gate output; never claim pass without it.
- **≥2 approaches before non-trivial implement:** design-time via `clarify-and-plan`;
  if skipped, ask the user for options yourself when the change is non-trivial.

## How to use this menu

1. Match the user's intent to one row below.
2. Tell them the recommended chain (skill names + lane).
3. **Invoke those skills** (or tell the user to); do **not** re-run the old
   frame→implement orchestrator inside `build-loop`.

Status legend: unmarked = skill exists today; `（planned Wave N）` = not landed yet.

---

## Workflows

### New feature / non-trivial change

1. `clarify-and-plan` (Lane A method: design + plan; ADR via `architecture-decision-records` when needed)  
2. `work-lanes` Lane A while docs are written; then Lane B to implement  
3. Apply **bounded fix retries ≤3** (above) while tests are red  
4. `merge-code-review` (or `code-review` for teaching split); receiving feedback → merge-CR appendix  
5. `/ship-gate` → `work-lanes` Lane C  

### Bug / unexpected failure

1. `systematic-debugging`  
2. `work-lanes` Lane B  
3. Bounded fix retries ≤3  
4. `merge-code-review`  
5. `/ship-gate` → Lane C  

### Multi-task plan execution

1. Written plan from `clarify-and-plan` / `docs/design/plans/*`  
2. `multi-task-protocol`  
3. Final wide review via `merge-code-review`  
4. `/ship-gate` → Lane C  

### Document delivery (T / P / D)

1. `document-delivery` — modes Technical / Present / Design  
2. `doc-verify`  
3. Ship docs via Lane A commit or Lane C if remote needed  

### Frontend UI

1. `frontend-craft` (+ Lane A design if needed)  
2. Implement under Lane B  
3. `browser-verify`  
4. Review → `/ship-gate` → Lane C  

### Isolated / parallel approaches

1. `using-git-worktrees` (optional hard-problem mode)  
2. Implement per isolate  
3. Compare → review → ship-gate → Lane C  

### CI red (independent jobs)

1. Ask before starting: `parallel-ci-triage`  
2. Re-run gates / Actions  
3. `ship-gate` → Lane C when green  

### Incident / production outage

1. `incident-response` — mitigate first  
2. Root cause → `systematic-debugging`  
3. Postmortem: `docs/templates/postmortem.md`  
4. Hotfix still obeys Lane C gates (override must be explicit)  

### Pre-ship only

1. `/ship-gate` (gates + `merge-code-review`)  
2. `work-lanes` Lane C  

### Architecture improvement (not a merge gate)

1. `improve-codebase-architecture`  
2. Optionally feed findings into `clarify-and-plan`  

### Fit / garden skills in this repo

1. `skill-fit` (fit checklist + gardening + scanner)  
2. Update **this file** (`skills/build-loop/workflows/recommended.md`) if menu entries changed  
   (`docs/workflows/recommended.md` is only a stub pointer)  

### Local commit hooks (optional)

1. Install `kits/git-hooks` into the target repo  
2. Still run `/ship-gate` before Lane C ship claims  

---

## Already-available skills (quick index)

| Skill | Role |
| --- | --- |
| `work-lanes` | Outbox lanes A/B/C + remote gates |
| `ship-gate` | Pre-ship: `run-gates` + merge-code-review |
| `build-loop` | **Thin entry only** — opens this skill-local menu and matches a chain |
| `clarify-and-plan` | Lane A: clarify, design, plan (hard-gate before code) |
| `architecture-decision-records` | ADR under `docs/adr/` |
| `systematic-debugging` | Root cause before fix |
| `multi-task-protocol` | Subagent-per-task plan execution |
| `merge-code-review` | Merge-readiness bug-hunt (+ receiving-feedback appendix) |
| `code-review` | General / teaching review checklist |
| `hunk-walkthrough` | Diff walkthrough |
| `commit-message` | Commit message drafting |
| `research-case-card` | Research case card from SearXNG evidence |
| `document-delivery` | T / P / D finished docs |
| `doc-verify` | Markdown + broken-link gate |
| `incident-response` | SEV → mitigate → postmortem |
| `frontend-craft` | UI orchestration → `kits/frontend-craft` |
| `browser-verify` | Browser QA / screenshots |
| `parallel-ci-triage` | Split CI failures across agents |
| `using-git-worktrees` | Isolated worktrees / hard-problem |
| `improve-codebase-architecture` | Architecture options (not merge gate) |
| `skill-fit` | Fit skills to repo + scanner checklist |

## Docs

| Doc | Role |
| --- | --- |
| `docs/design/2026-07-26-review-framework.md` | Review entries + axes |
| `docs/mcp-presets.md` | MCP vs Skill/Kit; Superpowers C note |

## Related

- Intake decisions: `docs/design/2026-07-26-toolkit-intake-decisions.md`
- Docs tree: `docs/README.md`
