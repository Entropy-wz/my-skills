---
name: work-lanes
description: Govern how the maintainer's own local work is tracked and shipped through three lanes (design-only / local-code / ship). Invoke to pick a lane, load normative docs, enforce commit-authorship hygiene, and gate anything that touches the remote. Trigger phrases — "work lanes", "which lane", "what lane am I in", "ready to push", "ready to ship", "开工分道", "确认工作车道", "能推送吗", "可以开 PR 吗".
disable-model-invocation: true
---

# Work Lanes

Govern how *my own* local work is tracked and shipped. This is the outbox: an intake/triage
workflow decides whether an incoming issue/PR is ready; **work-lanes decides how my work leaves
this machine** — what may be committed, pushed, issued, or turned into a PR, and when.

Every action that touches the remote (`git push`, `gh issue create`, `gh pr create/edit`)
passes through a **lane gate**. Lanes never escalate silently. When unsure, stop and ask.

## When to use this / when to use triage instead

- Use **work-lanes** when *you* are about to write, commit, push, open issues for, or ship
  your own changes and want the remote-touching rules enforced.
- Use your **intake / triage** workflow when evaluating *incoming* issues or external PRs for
  readiness.
- They compose: triage may produce a `ready-for-agent` brief; work-lanes governs the
  local execution and shipping of that brief.

## Invocation

The maintainer invokes `/work-lanes` and describes intent in natural language:

- "开工，先把方案写清楚" → likely Lane A
- "本地把这个 bug 修了" → likely Lane B
- "本地过了，准备推送开 PR" → likely Lane C
- "我现在在哪个车道？" / "which lane am I in?"
- "can I push this?" → confirm lane, run gate

Interpret intent, propose a lane, and **confirm before any remote action**.

## Session bootstrap (run once at start, or when lane is unclear)

1. **Pick a lane.** Classify the work into exactly one of A / B / C (below). If ambiguous,
   present the two most likely and ask.
2. **Confirm.** State the lane and, in one line, what it permits and forbids. Get explicit
   agreement before acting on the remote.
3. **Load normative docs** (§Normative sources) and reconcile the plan against them. If the
   requested action contradicts a doc, surface the conflict — do not invent process.
4. **Summarize the plan**: lane, what you'll do locally, what (if anything) will touch the
   remote, and what gate must pass first.

## The three lanes (code ↔ remote)

| Lane | Meaning | Remote (push / issue / PR) |
| --- | --- | --- |
| **A `design-only`** | Local design docs, plans, notes only | **NO** push, **NO** new issues/PRs unless the user overrides. May draft issue/PR text locally. |
| **B `local-code`** | Implement / fix locally | Local commits OK. **NO** push, **NO** open/update PR unless the user overrides. |
| **C `ship`** | Local done → push | Push allowed. PR create/update allowed per issue rules. Gate must pass first. |

**Never silently escalate A→B→C.** Each transition is a decision the user makes. If work
naturally outgrows its lane ("this design needs a quick prototype to validate"), name it and
ask to switch lanes rather than drifting.

### Per-lane playbook

**Lane A — design-only**
- Allowed: write/edit local docs under `docs/`, ADR drafts, plans, notes; draft issue or PR
  *text* into a local file for later.
- Forbidden: `git push`, `gh issue create`, `gh pr create/edit`. No remote issues yet — local
  design only.
- Commits: local doc commits are fine if the user wants history, but nothing leaves the machine.

**Lane B — local-code**
- Allowed: edit code, run tests, `git add` / `git commit` locally, iterate.
- Forbidden: `git push`, opening or updating a PR, creating tracker issues — unless the user
  explicitly overrides for a one-off.
- Every commit obeys the §Commit hygiene checklist.

**Lane C — ship**
- Allowed: `git push`, `gh issue create` (umbrella + children), `gh pr create/edit` per the
  §Issue playbook.
- Precondition: the §Gate checklist has passed and results are reported. No "done" claim
  without gate evidence.

## Normative sources (read before implementing or filing)

Read and obey; do not invent process that contradicts these. Skip any that your repo lacks:

- Repo context + decisions — a top-level context doc (e.g. `CONTEXT.md`) and any ADRs under
  `docs/adr/`.
- Agent/process docs — anything under `docs/agents/` (issue-tracker conventions, domain notes,
  triage labels, code-review policy). If you use the [mattpocock/skills](https://github.com/mattpocock/skills)
  engineering set, this layout is created by running `/setup-matt-pocock-skills` once per repo
  (installed via `npx skills@latest add mattpocock/skills`).
- Behavioral rules — `AGENTS.md`, `CONTRIBUTING.md`, and `.cursor/rules/` (language, style).
- Recent history — `git log --oneline -20` on the branch and the default branch for message
  tone and Conventional Commits scope conventions.

## Commit hygiene checklist (every commit, Lanes B & C)

The human owner is the **sole** git author/committer. Enforce before each commit:

- [ ] **No AI attribution anywhere in commit metadata.** Never add `Co-authored-by`,
      co-contributor, or trailer identities naming an AI/agent tool ("Cursor" / "Claude" /
      "Copilot" / "Codex" / "AI" / "agent" / "vibe coding" or any variant). Author and
      committer identity is the human owner.
- [ ] **Strip auto-added AI trailers.** If tooling injected a `Co-authored-by:` for an AI,
      remove it before the commit lands. Verify with `git log -1 --format='%an <%ae>%n%b'` and
      re-check on amend.
- [ ] **Conventional Commits** subject: `feat(scope): …` / `fix(scope): …` / `docs(scope): …`.
- [ ] **Branch name** uses the human username segment: `username/<issue#>-<type>-<slug>`
      (never a bare `feat/…` top-level; the username is always the human owner).
- [ ] AI assistance may be mentioned in the **PR body only** if repo policy already allows it —
      prefer silence in commit metadata.

## Issue playbook (tied to lane) — GitHub sub-issues

Uses GitHub native sub-issues. Requires `gh >= 2.94.0` (check `gh --version`; else fall back to
`Refs`/`Fixes` text linking). Follow your repo's issue-tracker doc for titles, prefixes/labels,
and language conventions; the commands below are the mechanics.

- **Lane A (design-only):** do **not** create issues. Draft issue text locally if useful.
- **Opening a new PR (Lane C):** ensure an **umbrella** issue exists first, then create the
  relevant **child** issues under it. The PR links each child with `Fixes #<child>` and the
  umbrella with `Refs #<umbrella>`.

  ```bash
  gh issue create --title "<umbrella title>" --body "$(cat <<'EOF'
  Why:
  <...>
  What to build:
  <...>
  EOF
  )"
  gh issue create --title "<child title>" --parent <umbrella#> --body "$(cat <<'EOF'
  Why:
  ...
  Acceptance Criteria:
  - [ ] ...
  EOF
  )"
  ```

- **PR already open:** a new slice becomes a **child** attached under the PR's *existing*
  umbrella — do **not** invent a second umbrella.

  ```bash
  gh issue create --title "<new slice title>" --parent <existing-umbrella#> ...
  # or attach an existing issue:
  gh issue edit <existing-umbrella#> --add-sub-issue <child#>
  gh issue edit <child#> --set-parent <existing-umbrella#>
  ```

- **Titles/bodies:** follow your repo's convention for language and prefixes (check recent
  issues and the issue-tracker doc). Keep identifiers, paths, labels, and refs in English.
  Keep structural headers (`Why`, `What to build`, `Acceptance Criteria`, `Verification`,
  `Blocked by`, `Changes`, `Notes`) consistent across issues.

## Gate checklist (must pass before any Lane C push/PR "done" claim)

**Prefer `/ship-gate` first** (runs `tools/run-gates` + merge-code-review and produces Verification).
If ship-gate is unavailable, fall back to the manual steps below.

1. **Discover the gates the repo defines** — check `package.json` scripts, CI workflows under
   `.github/workflows/`, `Makefile`, and any process docs. Run all of them: lint, typecheck,
   unit, integration, and any schema/migration checks.
2. **Smoke / real-data verification** when the change touches data, external-integration, or
   migration paths. Run a smoke against real data where safe and record **what was run, env,
   and account/date** — never secrets or credentials.
3. **Report results** in the session *and* in the PR/issue **Verification** section. If a gate
   fails or was skipped, say so explicitly; do not claim "done".

## Optional: umbrella status comment (Lane C only, when the user wants tracker updates)

Only post when lane is `ship` and the user asks for a tracker update. Adapt to your repo's
language convention:

```markdown
> *This was generated by AI during work-lanes.*

## Work Notes

**Shipped in this slice:**
- <point>

**Verification:**
- gates: <lint / typecheck / test results>
- smoke: <what ran, env, account/date — no secrets>

**Still open under this umbrella:**
- #<child> — <one line>
```

## Relationship to triage

Triage = *inbox readiness* (is an incoming issue/PR ready to work?).
work-lanes = *outbox discipline* (how does my work leave this machine, safely and tracked?).
Never let a lane gate be bypassed because triage already labeled something ready.
