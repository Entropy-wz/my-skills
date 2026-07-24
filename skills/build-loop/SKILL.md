---
name: build-loop
description: Guided build loop for a stated problem — restate the problem, propose 2+ approaches, let the user pick, implement in a mode (fix / feature / refactor / spike), auto-run tests with bounded fix retries, then hand off to review. Orchestrates other skills; never ships silently. Trigger phrases — "build-loop", "/build-loop", "propose options then build", "solve this properly", "出几个方案再实现", "让我选方案", "跑测试再 review".
disable-model-invocation: true
---

# Build Loop

A guided loop that turns a stated problem into reviewed, test-green code. It is an
**orchestrator**: it sequences the phases and hands the review/ship steps off to other
skills rather than reimplementing them.

Fixed sequence — never skip a phase, never silently escalate:

```
frame → propose (≥2) → user picks → implement (mode) → test (bounded fix) → review → stop
```

The loop **stops at review**. Pushing / PRs are governed by the `work-lanes` skill, not here.

## When to use / when not

Use when the user hands over a real problem and wants options before implementation, with
tests and review folded in ("solve this, but show me approaches first").

Don't use when:
- The change is trivial and the approach is obvious → just do it.
- The user only wants a review of existing changes → use `merge-code-review` / `code-review`.
- The user is deciding how work leaves the machine (push / issue / PR) → use `work-lanes`.

## Phase 1 — Frame the problem

Restate the problem in one or two sentences and confirm you understood it. Surface:
- The observable symptom or desired outcome (not the presumed cause).
- Constraints (perf, compat, deadline, files that must not change).
- How success will be verified.

If the problem is a bug, reproduce it first (command + observed vs expected). A problem you
can't state crisply is not ready to solve — ask.

## Phase 2 — Propose ≥2 approaches

Present **at least two** genuinely different approaches (not one plan with cosmetic variants).
For each:

```
### Option N — <short name>
- Approach: <how it works, 2-3 lines>
- Touches: <files / modules>
- Pros: <what it buys>
- Cons / risk: <cost, failure modes>
- Effort: <S / M / L>
```

End with a one-line **recommendation** and why. Then stop and let the user pick — do **not**
start implementing on your own guess. Use a structured choice (AskQuestion) when available.

`spike` mode may present a single quick sketch instead of full options; every other mode needs ≥2.

## Phase 3 — User picks

Wait for an explicit choice. If the user modifies an option or blends two, restate the final
plan in one line and confirm before building.

## Phase 4 — Implement (pick a mode)

Classify the work into exactly one mode. Modes differ in proposal depth, test rigor, and
review depth — like `work-lanes` lanes, they never escalate silently. If the work outgrows its
mode mid-flight, name it and ask to switch.

| Mode | When | Tests | Review depth | Ship |
| --- | --- | --- | --- | --- |
| **fix** | a bug with a repro | **write the failing repro test first**, then fix until green | `merge-code-review` (low/medium) | via `work-lanes` |
| **feature** | new capability | tests for the new behavior; use TDD if available | `merge-code-review` (medium/high) | via `work-lanes` |
| **refactor** | behavior-preserving change | existing tests are the safety net; add characterization tests for gaps; **must stay green throughout** | `merge-code-review`, focus on behavior-preservation | via `work-lanes` |
| **spike** | throwaway prototype / exploration | smoke check only; full gate skipped | skip formal review; summarize learnings | **do not ship** — spike code is disposable |

Implement the chosen option. If reality diverges from the approved plan (the option turns out
unworkable), stop and re-propose rather than quietly doing something else.

## Phase 5 — Test (bounded fix loop)

1. **Discover the gate**: test/lint/typecheck commands from `package.json` scripts, `Makefile`,
   CI under `.github/workflows/`, or the repo's conventions (pytest, go test, etc.).
2. **Run** the relevant tests (scope to the change when the suite is large; run the full suite
   before declaring done).
3. **If red**: analyze the failure, fix, and rerun. Retry at most **3 times**. After the third
   still-failing run, **stop** — report exactly what's failing, your best hypotheses, and ask
   the user how to proceed. Do not loop indefinitely.
4. **Never claim done without green evidence.** Paste the passing test output.

`spike` mode runs a smoke check instead of the full gate.

## Phase 6 — Review (hand off)

Once tests are green, hand off to the review skill — do not hand-roll a review:

- Default: invoke **`merge-code-review`** on the diff since the loop's starting point
  (advisory, ranked bug hunt). Map effort from the mode (fix→low/medium, feature→medium/high).
- For a neutral Standards‖Spec teaching split, use **`code-review`** instead.

Surface the findings. Apply fixes only if the user asks; each applied fix re-enters Phase 5
(tests must stay green).

`spike` mode skips formal review and instead summarizes what was learned and what to keep.

## Stop / handoff

The loop ends here with: what was built, the passing test evidence, and the review findings.
**Shipping is out of scope** — if the user wants to push / open issues / open a PR, switch to
`work-lanes` (Lane C gate). Never `git push` or `gh pr create` from inside build-loop.

## Progress checklist

Copy and track:

```
- [ ] Phase 1: problem framed + (if bug) reproduced
- [ ] Phase 2: ≥2 approaches presented with tradeoffs + recommendation
- [ ] Phase 3: user picked an option
- [ ] Phase 4: mode chosen; implemented per the approved option
- [ ] Phase 5: tests discovered + run; green (or stopped after 3 tries and asked)
- [ ] Phase 6: review handed to merge-code-review; findings reported
- [ ] Stopped at review — ship handed to work-lanes if requested
```

## Guardrails

- Never skip Phase 2→3: no implementation before the user picks an approach.
- Always ≥2 approaches except `spike`.
- Never escalate modes silently.
- Bounded fix retries (≤3), then stop and ask — no infinite fix loops.
- No "done" claim without pasted green test output.
- Never push, open PRs, or create issues — that belongs to `work-lanes`.
- Don't reimplement review; hand off to `merge-code-review` / `code-review`.

## Example invocations

- "/build-loop the export is dropping the last row — fix it." (→ fix)
- "Propose a couple of approaches for adding rate limiting, then build the one I pick." (→ feature)
- "Refactor this module, keep behavior identical, run the tests." (→ refactor)
- "Spike a quick prototype of the new parser so we can see if it's viable." (→ spike)
- "出两个方案给我选，然后实现、跑测试、再 review。"
