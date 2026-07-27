---
name: merge-code-review
description: Pre-merge, mentor-style review of the diff since a fixed point. Hunts real correctness bugs with a find→verify→cap pipeline (Critical/Important/Nit), and folds in Spec-match and Standards/smell checks as secondary axes. Advisory only — never Approves or Requests-changes. Use when the user wants a merge-readiness review, a "thorough" or "quick" bug review of a PR/branch/WIP, or says "review before merge" / "find bugs in my changes".
---

Merge-readiness review of the diff between a fixed point and `HEAD`. The primary deliverable is **grounded correctness findings that would actually get fixed before merge** — ranked, capped, and each backed by a concrete failure scenario. Spec-match and Standards/smells ride along as secondary axes.

This is the pre-merge / mentor variant. If your repo also has a pure teaching-style two-axis (Standards‖Spec, no rerank) review skill, use that for neutral teaching reviews instead. This skill *includes* those axes but adds a correctness bug-hunt pipeline and produces one ranked report.

**AI review is advisory.** Never Approve, never Request-changes, never merge. Surface findings; the human owns the architecture/product/merge call.

## When to use / when not

Use when:
- The user wants a review **before merging** a branch/PR/WIP ("is this mergeable?", "find bugs", "mentor review").
- They want ranked correctness findings, not a style lecture.

Don't use when:
- They want a neutral Standards‖Spec teaching split with no reranking → use a dedicated two-axis review skill if present.
- They want line-level rule-matching + inline PR comments at scale → use a dedicated line-level reviewer (an OCR- or CodeRabbit-style tool) if your repo runs one.
- There is no diff (empty/clean working tree against the base).

## Effort levels

Default is **medium**. Map the user's words: "quick"/"fast"/"just the obvious stuff" → low; "thorough"/"deep"/"be paranoid" → high; "ultra"/"exhaustive" → ultra.

| Effort | Bias | Subagents | Angles | Cap | Style/smells | Missing tests |
| --- | --- | --- | --- | --- | --- | --- |
| low | speed | none (single pass) | core correctness only | ≤4 | skip | skip |
| medium | precision | optional finders + verify | core + a few extra | ≤8 | judgement only | note if central |
| high | recall | multiple finders + recall-biased verify | full list incl. cleanup | ≤10 | judgement only | flag gaps |
| ultra | recall | max finders, cross-file | full + data-flow | ≤12 | on request | flag gaps |

- **low**: one diff pass, no subagents. Only report hunk-visible runtime correctness bugs. Skip test/fixture hunks. No style, no missing-tests, no naming.
- **medium**: precision-biased. Run a few finder angles then verify; drop anything not at least *plausible*.
- **high**: recall-biased. More angles + recall-biased verify; keep plausible rare-path bugs; add reuse/simplification/convention cleanup.
- **ultra**: high + cross-file data-flow tracing; use only when explicitly requested (token cost).

## Framework

See `docs/design/2026-07-26-review-framework.md`. This skill is the **merge-readiness**
entry. General/teaching reviews → `code-review`.

### Optional Security / find-bugs axis

When the user asks for security focus (or ship-gate context warrants it), add a short
pass over the **diff only**:

- Injection (SQL/command/template), XSS, authz/IDOR, secret leakage, unsafe deserialization
- Dangerous defaults (open CORS, debug left on), path traversal on file APIs

Report under Critical/Important with the same `failure_scenario` rule. Do **not** start a
separate review skill. Skip this axis on `low` effort unless requested.

## Process

### 1. Pin the fixed point
Use whatever the user named (SHA, branch, tag, `main`, `HEAD~5`). If none given, ask. Confirm it resolves and the diff is non-empty *before* any subagent work:
```
git rev-parse <fixed-point>
git diff <fixed-point>...HEAD          # three-dot: compare against merge-base
git log <fixed-point>..HEAD --oneline
```
A bad ref or empty diff fails here, not inside a subagent.

### 2. Optional PR / issue context (gh)
If reviewing a PR or the commits reference issues:
```
gh pr view <n> --json title,body,files
gh pr diff <n>
```
Pull `Fixes #123` / issue refs from commit messages for the Spec axis. Skip cleanly if `gh` is unavailable or there's no PR.

### 3. Identify axes sources
- **Spec source** (in order): issue refs in commits → path the user passed → PRD/spec under `docs/`, `specs/`, `.scratch/` matching the branch/feature → else ask; if none, Spec axis reports "no spec available".
- **Standards sources**: `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `.cursor/rules`, `AGENTS.md`, plus the Fowler smell baseline below.

## Parallel work

At medium+ effort, spawn finders/axes as **parallel `general-purpose` subagents** in a single message so their contexts don't cross-contaminate. At low effort do it all in one inline pass. Each subagent gets the diff command + commit list; it has no other access.

### Axis A — Spec (secondary)
Report: (a) spec requirements missing/partial; (b) behaviour in the diff not asked for (scope creep); (c) requirements implemented but wrong. Quote the spec line per finding. Skip if no spec.

### Axis B — Standards / smells (secondary; lighter at low effort)
Report documented-standard breaches (cite file + rule; can be hard violations) and baseline smells (always judgement calls; repo standard overrides; skip anything tooling enforces). At low effort, **skip this axis entirely**. Smell baseline (Fowler, *Refactoring* ch.3), each *what → fix*:
- **Mysterious Name** — name doesn't reveal intent → rename; if no honest name, design is murky.
- **Duplicated Code** — same shape in >1 hunk → extract, share.
- **Feature Envy** — method reaches into another object's data more than its own → move it.
- **Data Clumps** — same fields travel together → bundle into a type.
- **Primitive Obsession** — primitive standing in for a domain concept → give it a type.
- **Repeated Switches** — same switch on same type recurs → polymorphism / shared map.
- **Shotgun Surgery** — one change forces scattered edits → gather into one module.
- **Divergent Change** — one module edited for unrelated reasons → split.
- **Speculative Generality** — abstraction for needs the spec lacks → delete, inline back.
- **Message Chains** — long `a.b().c().d()` → hide behind one method.
- **Middle Man** — mostly-delegating class → call the real target.
- **Refused Bequest** — subclass ignores most of what it inherits → prefer composition.

### Axis C — Correctness pipeline (PRIMARY — the main value)
Three stages: **find → verify → cap**.

**Find.** For each changed hunk, read the hunk *and its enclosing function*. Hunt these angles:
- inverted / wrong condition; off-by-one and boundary; null/undefined deref; missing `await` / unhandled promise; swallowed or mislabelled errors; wrong-variable / copy-paste; removed guard or validation; resource leak (unclosed handle, missing cleanup); state mutated during iteration; concurrency / ordering assumption; type coercion surprise; changed public contract without callers updated.
- At high/ultra also: reuse/simplification opportunities and convention cleanup that affect correctness or maintainability.
- Every candidate MUST carry a concrete `failure_scenario` (inputs + steps → wrong result). No scenario → drop it.

**Verify.** Label each candidate:
- **confirmed** — the bug is demonstrable from the code as written.
- **plausible** — realistic rare/edge path; can't fully construct from the diff alone. Recall-biased verify (high/ultra) keeps these; precision-biased verify (low/medium) keeps a plausible finding only if the path is realistic and central.
- **refuted** — only when you can construct, from the code, why it *cannot* happen. Drop refuted.

**Cap.** Rank most-severe first and truncate to the effort cap. If more real bugs exist beyond the cap, say so in one line rather than padding.

Never invent findings. Every finding must quote or cite the diff hunk it comes from.

## Finding schema

Emit each finding with these fields:
- `file` — path
- `line` — line or range in the new file
- `short_summary` — ≤60 chars, scannable
- `summary` — one-paragraph explanation, grounded in the hunk
- `failure_scenario` — concrete inputs/steps → wrong outcome
- `category` — correctness | spec | standards | smell | cleanup
- `severity` — Critical | Important | Nit
- `verify` — confirmed | plausible | refuted (refuted excluded from report)

### Severity levels
- **Critical (P0)** — data loss, crash, security hole, wrong result on a common path. Always report. (Maps to a line-level tool's **High** if you run one.)
- **Important (P1)** — real bug on an edge/rare path, missing guard, contract break. Report. (Maps to **Medium**.)
- **Nit (P2)** — style, naming, micro-smell, subjective. **Silently discard** unless high+ effort *and* the user asked for nits. (Maps to **Low**.)

## Final report template

```
## Merge review — <fixed-point>...HEAD  (effort: <level>)

**Verdict:** <mergeable as-is / mergeable after Critical+Important / not ready> — advisory only, no Approve/Request-changes.
<n commits, m files, k findings kept (of j candidates)>

### Critical (P0)
- [file:line] short_summary — failure_scenario. (verify: confirmed|plausible)

### Important (P1)
- [file:line] short_summary — failure_scenario. (verify: …)

### Nits (P2)          # omit section entirely unless high+ and user asked
- [file:line] short_summary

### Spec gaps
- <missing / partial / scope-creep>, quoting the spec line.   # or "no spec available"

### Standards notes
- <documented-standard breaches + judgement-call smells>.     # or "skipped (low effort)"

### Verification suggested
- <specific tests/manual checks to confirm the plausible findings before merge>
```

## Silent discard rules
- Never spam style/naming/formatting. Nits are discarded unless effort is high+ **and** the user explicitly asked for them.
- Drop any finding without a concrete `failure_scenario`.
- Drop **refuted** findings entirely.
- Drop anything a linter/formatter/type-checker already enforces.
- Prefer one honest "N more minor items beyond the cap" line over padding to the cap.
- If a finding is a duplicate across axes, keep the correctness-axis version and note the overlap once.

## Out of scope
- No Approve / Request-changes / merge — advisory only.
- No architecture or product-fit verdict — that's the human's call; note concerns, don't rule.
- No rewriting the branch. Post GitHub comments or apply fixes **only if the user explicitly asks** (`gh pr comment`, or edit files).
- No full-repo scan — review is diff-scoped.
- No re-litigating tooling-enforced style.

## Example invocations
- "Review my branch before I merge — is it mergeable?"
- "Quick bug review of this PR." (→ low)
- "Do a thorough merge review since main." (→ high)
- "Find correctness bugs in the diff vs `v2.3.0`, skip style."
- "Mentor-review PR #142, P1/P2 only, no nits."
- "Ultra review origin/main...HEAD and suggest what to test."

## Appendix: Receiving review feedback

When the user (or you) is **acting on** review findings — from this skill, a human, or CI —
follow this reception protocol. It does not change the advisory nature of the review itself.

**Core:** verify before implementing; ask before assuming; technical correctness over
performative agreement.

1. **Read** the full feedback without reacting or patching mid-read.
2. **Classify** each item: agree (evidence-backed) / need clarification / disagree (with
   counter-evidence: repro, test, spec, or standard).
3. **Ask** on anything unclear or technically questionable — do not silently "fix" a
   misunderstanding.
4. **Implement** only agreed items; re-run relevant tests (bounded retries ≤3 per
   `docs/workflows/recommended.md`).
5. **Decline** items that are wrong or out of scope with a short technical rationale —
   never rubber-stamp to be polite.

This appendix is process for the implementer side. It does **not** authorize Approve /
Request-changes / merge.
