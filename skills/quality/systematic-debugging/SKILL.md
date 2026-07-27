---
name: systematic-debugging
description: Root-cause debugging before any fix — reproduce, isolate, hypothesize, verify, then minimal fix + regression test. Use for bugs, test failures, or unexpected behavior. Trigger phrases — "systematic-debugging", "系统排障", "先找根因", "debug systematically".
disable-model-invocation: true
---

# Systematic Debugging

## Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Symptom patches without understanding cause are failures. Violating the letter of this
process violates the spirit of debugging.

## When to use / when not

Use for any bug, failing test, or unexpected behavior before proposing a fix.

Don't use when:

- Greenfield feature design → `clarify-and-plan`
- User already has a verified root cause and only wants the patch applied
- Pure docs / ADR work

No direct coupling to `ship-gate` — after the fix is verified, normal review → ship-gate.

## Process

### 1. Reproduce

- Exact steps; expected vs actual
- Stable vs intermittent
- Environment (OS, runtime, browser, branch)

If you cannot reproduce, ask — do not guess-fix.

### 2. Isolate

Narrow where it lives:

- Binary-search / comment-out halves of the suspect surface
- `git bisect` when "it worked before"
- Layer: frontend vs backend vs DB vs API vs single component

### 3. Hypothesize

One specific, testable claim: "X because Y" — not "data is weird".

### 4. Test the hypothesis

Smallest probe (log, breakpoint, failing test). Wrong → new hypothesis. Right → root cause.

### 5. Fix and verify

- Minimal fix for the root cause
- Re-run original reproduction — should be gone
- Check regressions; add a test that would have caught this
- Bounded retries ≤3 on remaining failures (`docs/workflows/recommended.md`), then stop and ask

## Tools by scenario

| Scenario | Tool |
| --- | --- |
| Worked before | `git bisect` |
| Don't know where it runs | Entry/exit logging |
| Bad data | Inspect each transform |
| Prod-only | Compare env; sanitize prod-like repro |
| Intermittent | Races, timing, uninitialized state |
| Useless error text | Find throw site in repo |

## Common patterns

Off-by-one · null/undefined · races · stale closures · `==` coercion · missing `await` ·
env mismatch (local vs CI/prod).

## Handoffs

| Next | When |
| --- | --- |
| Lane B implement | Root cause known; apply minimal fix |
| `merge-code-review` | Fix landed; want merge-readiness |
| `incident-response` | Production outage — mitigate first, then return here for root cause |
| `clarify-and-plan` | "Bug" is actually missing product design |

## Guardrails

- Never guess — evidence first.
- Fix root cause, not symptoms.
- 15 minutes stuck → re-isolate; document failed attempts.
- No push / PR / issues from this skill.
