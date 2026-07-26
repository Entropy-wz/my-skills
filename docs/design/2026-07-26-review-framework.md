# Review framework (toolkit)

> Status: landed with Wave 3 of `2026-07-26-toolkit-intake-decisions.md`.  
> Goal: one framework, multiple **entries/axes** — not four parallel review skills.

## Entries

| Entry | Skill | When |
| --- | --- | --- |
| Merge-readiness | `merge-code-review` | Before merge / ship-gate; correctness bug-hunt primary |
| General / teaching / quick | `code-review` | Standards‖Spec or fast checklist; not merge ceremony |
| Diff walkthrough | `hunk-walkthrough` | Explain hunks; not a gate |
| Architecture (not a merge gate) | `improve-codebase-architecture` | Deepening / structure options → may feed `clarify-and-plan` |

## Axes (hang off entries — do not spawn a 4th review skill)

| Axis | Where | Notes |
| --- | --- | --- |
| Correctness | `merge-code-review` primary | find→verify→cap |
| Spec / Standards | both merge-CR (secondary) and `code-review` | |
| Security / find-bugs | optional pass inside merge-CR (see its Security axis) | Sentry-inspired, shortened |
| TDD / test sufficiency | both | missing tests downgrade confidence |
| Receiving feedback | `merge-code-review` appendix | implementer side |

## Process quality (not CR)

| Concern | Skill / kit |
| --- | --- |
| Root cause before fix | `systematic-debugging` |
| Skill text safety / repo fit | `skill-fit` (includes scanner checklist) |
| Local commit hooks | `kits/git-hooks` |
| Outbound gates | `ship-gate` / `run-gates` |

## Non-goals

- No Approve / Request-changes bots as policy.
- No second “mentor review” skill beside merge-CR.
- No auto-start security axis — user or ship-gate prompt.
