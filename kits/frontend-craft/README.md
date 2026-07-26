# Kit: frontend-craft

Runnable assets for frontend design + UI acceptance. Orchestration lives in
`skills/frontend/frontend-craft` (thin entry) — this kit is **not** installed as a duplicate skill
(no `skill/SKILL.md` here on purpose).

## Prerequisites

- Target app with a known `npm`/`pnpm`/`yarn` dev script (or static server)
- Cursor Browser tools for `browser-verify`
- Optional: Playwright (project-local) for lasting e2e

## Quick start

```powershell
# from repo root — read the skill, use templates/scripts below
# templates:
#   kits/frontend-craft/templates/ui-review.md
# checklist:
#   kits/frontend-craft/tools/a11y-checklist.md
```

Dev-server smoke helper (optional):

```powershell
powershell -File kits/frontend-craft/tools/smoke-ui.ps1 -Url http://127.0.0.1:3000
```

## Layout

| Path | Role |
| --- | --- |
| `tools/smoke-ui.ps1` | Ping URL / print curl-style smoke |
| `tools/a11y-checklist.md` | Manual a11y checklist |
| `templates/ui-review.md` | Acceptance record (viewports / theme / network) |
| `references/design-constraints.md` | Anti-generic-AI UI constraints (for agents) |

## Ownership

- **Kit** = assets  
- **Skill** `skills/frontend/frontend-craft` = orchestration  
- **Skill** `skills/frontend/browser-verify` = browser QA steps  
