---
name: frontend-craft
description: Orchestrate frontend design constraints, implementation norms, and browser acceptance using kits/frontend-craft assets and browser-verify. Trigger phrases — "frontend-craft", "前端框架", "UI 验收", "按 frontend-craft 做".
disable-model-invocation: true
---

# Frontend Craft

Thin orchestration entry. **Assets** live in `kits/frontend-craft/` (this skill does not
duplicate them).

## When to use / when not

Use for UI feature work that needs design direction + acceptance evidence.

Don't use for pure API/backend changes, or when the user only wants a code review.

## Flow

1. **Lane A (if design unsettled)** — constraints from
   `kits/frontend-craft/references/design-constraints.md`; capture in design doc via
   `clarify-and-plan` when non-trivial.
2. **Lane B implement** — apply constraints; prefer project design system if one exists.
3. **Accept** — invoke `browser-verify`; fill
   `kits/frontend-craft/templates/ui-review.md` (copy into the project or docs).
4. **Smoke (optional)** — `kits/frontend-craft/tools/smoke-ui.ps1 -Url <dev-url>`.
5. **Review → ship-gate → Lane C** as usual.

## Guardrails

- Kit = assets; this skill = orchestration only.
- Do not vendor long upstream SKILL bodies; point at `references/design-constraints.md`.
- No remote ship from this skill.
