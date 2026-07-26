---
name: clarify-and-plan
description: Lane A method — clarify requirements (one question at a time, optional grill), propose 2–3 approaches, get sectional design approval, write design doc + bite-sized implementation plan; hard-gate before code. Trigger phrases — "clarify-and-plan", "澄清并对齐", "先设计再计划", "grill 一下", "写设计再写计划".
disable-model-invocation: true
---

# Clarify and Plan

**Lane A method** (orchestration layer): turn a rough intent into an approved design and
an executable plan. Does **not** replace `work-lanes` lane choice or remote gates.

Paths (under the target repo, usually my-skills or the project being designed):

- Design: `docs/design/YYYY-MM-DD-<topic>.md`
- Plan: `docs/design/plans/YYYY-MM-DD-<topic>.md`
- ADR (when needed): via `architecture-decision-records` → `docs/adr/NNN-….md`

## When to use / when not

Use for new features, behavior changes, or non-trivial refactors before implementation.

Don't use when:

- Trivial one-liner with an obvious approach (still state the plan in one sentence)
- Pure bugfix with clear root cause → `systematic-debugging` first
- User only wants to ship existing work → `ship-gate` / `work-lanes` Lane C
- Hotfix with explicit skip — note the skip orally; prefer a short post-hoc design/ADR

## Hard gate

Do **not** write implementation code, scaffold projects, or invoke implement/fix skills
until the user has approved the **written** design (and, for multi-step work, the plan).
User may explicitly skip; record that in the session.

## Stages (in order)

1. **Context** — skim relevant docs, ADRs, recent commits.
2. **Clarify** — ask **one question at a time** (purpose, constraints, success criteria).
   Optional **grill mode**: pressure-test assumptions; can draft glossary / ADR notes as you go.
3. **Approaches** — present **2–3** genuinely different options with tradeoffs + recommendation.
4. **Design sections** — present the design in digestible sections; get approval per section
   (or batch if the user prefers).
5. **Write design doc** — save to `docs/design/YYYY-MM-DD-<topic>.md`.
6. **Self-review** — fix placeholders, contradictions, ambiguity, scope creep inline.
7. **User reviews the file** — ask them to read the path; revise if requested.
8. **Hard decisions** — if hard to reverse / multi-option tradeoff → invoke or draft via
   `architecture-decision-records`.
9. **Write plan** — `docs/design/plans/YYYY-MM-DD-<topic>.md`:
   - Assume reader has little repo context
   - Bite-sized tasks (each testable); YAGNI; note files to touch
   - Prefer TDD notes where tests matter
10. **Stop** — hand off: Lane B implement, or `multi-task-protocol` if many independent tasks.
    Shipping stays with `work-lanes`.

## Handoffs

| Next | When |
| --- | --- |
| `work-lanes` Lane A | Already in A while writing docs; confirm lane if unclear |
| `architecture-decision-records` | Step 8 |
| `multi-task-protocol` | Plan has multiple independent tasks |
| `systematic-debugging` | Problem is a bug, not a greenfield design |
| `work-lanes` Lane B | User approves plan and wants code |

## Guardrails

- One clarifying question at a time (unless user asks for a batch).
- No implementation before approval (see Hard gate).
- Plans live under `docs/design/plans/`, not `docs/superpowers/plans/`.
- Never push / open issues / PRs from this skill.
