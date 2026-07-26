---
name: code-review
description: General / teaching / quick code review entry — Standards and Spec axes, prioritized feedback. Use when not doing a full merge-readiness bug-hunt (that is merge-code-review). Trigger phrases — "code-review", "/code-review", "快速审查", "教学向 review", "Standards Spec".
disable-model-invocation: true
---

# Code Review (general entry)

Part of the [review framework](../../docs/design/2026-07-26-review-framework.md).

Use this for **general, teaching, or quick** reviews. For pre-merge correctness bug-hunt
with find→verify→cap, use **`merge-code-review`** instead.

## When to use / when not

Use when:

- User wants a readable Standards ‖ Spec split
- Quick checklist review without subagent machinery
- Teaching / mentoring tone on a diff or file set

Don't use when:

- Merge-readiness / "find bugs before merge" → `merge-code-review`
- Line-by-line hunk tour → `hunk-walkthrough`
- Architecture deepening → `improve-codebase-architecture`

## Effort

| Mode | Behavior |
| --- | --- |
| **quick** | Checklist only; ≤5 findings |
| **teaching** | Explicit Standards axis + Spec axis; explain why |
| **default** | Balanced checklist + prioritized notes |

## Checklist

- [ ] Logic correct; edges (null, bounds, concurrency)
- [ ] Security basics (injection, XSS, secrets, authz)
- [ ] Error handling on failure paths
- [ ] Naming / single responsibility / size
- [ ] Matches project style (`AGENTS.md`, `.cursor/rules`, CONTRIBUTING)
- [ ] Tests cover new/changed behavior (TDD axis: missing tests → lower confidence)

## Feedback format

- 🔴 **Must fix** — bug / security before merge
- 🟡 **Should improve** — quality, non-blocking
- 🟢 **Optional** — polish

Each item: location, why, concrete suggestion.

## Handoffs

- Escalating to merge-readiness → `merge-code-review`
- Acting on feedback → merge-CR **Appendix: Receiving review feedback**
- Shipping → `ship-gate` → `work-lanes` Lane C
