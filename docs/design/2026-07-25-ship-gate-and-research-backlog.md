# Design: ship-gate (work track A) + research backlog (study track B)

Date: 2026-07-25  
Status: approved in brainstorming (session)  
Repo: [Entropy-wz/my-skills](https://github.com/Entropy-wz/my-skills)

## Context

Existing toolkit strengths:

- Process skills: `work-lanes`, `build-loop`, `merge-code-review`, `hunk-walkthrough`, `commit-message`, `code-review`
- Capability kit: `searxng-search` (local meta-search + fetch/cache)

Gaps the owner named:

- **Work (A):** Gate discovery/execution and review chaining are weak before Lane C ship. Intake/branch/commit/PR discipline is already covered by `work-lanes` (triage-derived).
- **Study (B):** Research/case-card pipeline on top of SearXNG — deferred; tracker only this iteration.

Priority: **implement A first**; file B as backlog issue(s) when leaving design lane.

## Goals

### Track A (this implementation)

Before `work-lanes` Lane C push/PR, provide a repeatable pre-ship path:

1. Discover and run repo gates
2. Emit paste-ready Verification markdown
3. Default merge-readiness review (`merge-code-review`)
4. **Stop** — human decides whether to enter Lane C

### Track B (backlog only)

Umbrella for a later research pipeline: topic → SearXNG search → fetch excerpts → case-card / citation list. No paid search API.

## Non-goals

- Replace `work-lanes` (no push / issue / PR from ship-gate)
- Replace `build-loop` (implement → test loop)
- Generic CI platform or per-language test frameworks
- Auto `gh pr merge`
- Implementing the research pipeline in the same slice as ship-gate
- Auto-starting Docker / SearXNG unless a repo’s own `scripts/gates.*` does so

## Approach (chosen)

**Option 1:** new `skills/ship-gate` + shared `tools/run-gates.ps1` (and optional `run-gates.sh`).

Rejected:

- Thickening only `work-lanes` Lane C (bloated outbox skill)
- Packaging as a kit (no docker/infra; inconsistent with flat process skills)

## Architecture

```
User: /ship-gate
       → tools/run-gates.ps1  (discover + execute)
       → Markdown Verification (+ optional -Json)
       → if gates green (or user overrides): merge-code-review
       → optional hunk-walkthrough
       → STOP with "hand to work-lanes Lane C" or "not ready"
User: /work-lanes  (Lane C) uses Verification evidence
```

## `tools/run-gates.*` contract

### Invocation

```text
./tools/run-gates.ps1 [-Path <repo>] [-Json] [-DryRun]
```

Default `-Path`: walk up from cwd to `.git` root.

### Discovery order

1. If `scripts/gates.ps1` or `scripts/gates.sh` exists → **run only that** (highest priority).
2. Else collect common commands that exist:
   - `package.json` scripts: `lint`, `typecheck`, `test` (only if present)
   - `Makefile` targets: `lint`, `test`, `check` (only if present)
   - Toolkit convention: `scripts/check-layout.ps1` when present
3. `-DryRun`: print planned commands only.

### Exit codes

| Code | Meaning |
| --- | --- |
| 0 | All ran commands passed |
| 1 | At least one command failed |
| 2 | Commands found but environment missing (e.g. no npm) |
| 4 | No gates discovered |

### Human output (stdout)

Markdown block suitable for PR Verification:

- env / repo path / ISO timestamp
- each command → PASS/FAIL + duration
- summary line
- on failure: last ≤30 log lines (no secrets)

`-Json`: machine-readable summary for the skill.

### Bounds

- Per-command timeout (default 10–15 minutes) → FAIL
- Windows: prefer `.ps1`; `.sh` via Git Bash when available
- No implicit docker compose

### Resolution when skill is installed

Prefer, in order:

1. `tools/run-gates.ps1` inside the **target repo** (if vendored/copied)
2. `tools/run-gates.ps1` from the **my-skills** checkout (documented path / env `MY_SKILLS_ROOT`)
3. Fail with a clear message if neither exists

(Install script may later copy or link shared tools; v1 documents `MY_SKILLS_ROOT`.)

## `skills/ship-gate` flow

Triggers: `/ship-gate`, `pre-ship`, `出货前检查`, `ready to ship gates`.

1. Confirm repo root
2. Run `run-gates.ps1`
3. Paste Verification; if exit ≠ 0 → stop (unless user asks to review anyway)
4. Default `merge-code-review` vs `main` (overrideable); `+hunk` → `hunk-walkthrough`
5. Summarize: ready for Lane C vs not
6. **Stop** — never push / `gh pr create`

### Boundaries vs other skills

| Skill | Role |
| --- | --- |
| `work-lanes` | Lanes + remote; Lane C docs point to ship-gate first |
| `build-loop` | Implement + test + review; ship-gate is pre-ship re-gate |
| `merge-code-review` / `hunk-walkthrough` | Invoked by ship-gate; semantics unchanged |

Failures: do not auto-fix. Re-run `/ship-gate` after fixes.

## work-lanes touch

Add under Lane C / Gate checklist: prefer running `/ship-gate` (or equivalent) and attach its Verification before claiming ship.

## Track B — backlog issue draft

Full body: [`docs/design/drafts/2026-07-25-research-case-pipeline-issue.md`](drafts/2026-07-25-research-case-pipeline-issue.md)

Do **not** `gh issue create` until the owner leaves design-only / asks to ship tracker items.

## Acceptance (Track A implementation)

- [ ] `tools/run-gates.ps1` matches this contract; on my-skills runs `check-layout`
- [ ] `skills/ship-gate/SKILL.md` matches the flow; forbids push/PR
- [ ] `work-lanes` points Lane C at ship-gate
- [ ] Install scripts still install the new skill
- [ ] B issue draft on disk only
- [ ] `check-layout` / smoke-install still green

## Implementation order (for writing-plans)

1. `tools/run-gates.ps1` (+ optional `run-gates.sh`)
2. `skills/ship-gate/SKILL.md`
3. `work-lanes` Lane C pointer to ship-gate
4. Root / `tools/README.md` notes (`MY_SKILLS_ROOT`)
5. Local gate smoke on my-skills (`check-layout` via run-gates)
6. (Already drafted) Track B issue text under `docs/design/drafts/` — create on GitHub only when shipping tracker items
