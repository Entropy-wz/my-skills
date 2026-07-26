---
name: improve-codebase-architecture
description: Scan a codebase for module-deepening and seam opportunities, present ranked options, optionally grill via clarify-and-plan. Architecture advisory — not a merge gate. Trigger phrases — "improve-codebase-architecture", "架构加深", "deep modules", "找缝与边界".
disable-model-invocation: true
---

# Improve Codebase Architecture

Architecture advisory inspired by deep-module thinking (Matt Pocock / related). **Not** a
merge gate — do not block ship-gate on this skill alone.

## When to use / when not

Use when the user wants structural improvement options (boundaries, seams, testability,
AI-navigability).

Don't use for a routine PR bug-hunt → `merge-code-review`.

## Flow

1. **Scope** — whole repo vs path; constraints (no big-bang rewrite unless asked).
2. **Scan** — map modules, fat interfaces, tangled deps, missing seams, duplication.
3. **Options** — present 3–7 deepening opportunities ranked by leverage vs cost:
   - What shrinks in the interface / what complexity hides behind it
   - Files touched; risk; suggested first slice
4. **Choose** — user picks one (or none).
5. **Next** — for non-trivial picks, hand to `clarify-and-plan` (grill + design + plan).
   Small slices may go straight to Lane B.
6. Optional ADR via `architecture-decision-records` when the choice is hard to reverse.

## Deliverable shape

```markdown
## Architecture opportunities
### 1. <title> (leverage H/M/L · cost H/M/L)
- Observation:
- Proposal:
- First slice:
```

HTML report optional if the user wants a single file under `docs/design/`.

## Guardrails

- Advisory only — no silent large refactors.
- Prefer incremental slices over rewrites.
- No remote ship from this skill.
