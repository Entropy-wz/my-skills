---
name: browser-verify
description: Verify a running web app in the browser — open URL, check render/console/network, optional responsive/theme/a11y screenshots. Use after UI changes. Trigger phrases — "browser-verify", "visual QA", "浏览器验收", "verifying-in-browser".
disable-model-invocation: true
---

# Browser Verify

Runtime UI acceptance using Cursor Browser tools (or equivalent). Pairs with
`frontend-craft` / `kits/frontend-craft/templates/ui-review.md`.

## When to use / when not

Use after UI changes when a dev server (or preview URL) exists.

Don't use when there is no UI surface, or the user only wants static code review.

## Flow

1. **Find URL** — from user, terminals (dev server), or `smoke-ui.ps1` target.
2. **Open** the app in the browser tool; wait for settle.
3. **Baseline checks**
   - Visible render matches intent (no blank/error boundary)
   - Console: no unexpected errors
   - Network: no failed critical requests; note slowness/duplicates
4. **Optional matrices** (when user asks or frontend-craft acceptance needs them)
   - Responsive: ~375 / ~768 / ~1280 — screenshot each
   - Dark/light if the app supports theme
   - A11y pass using `kits/frontend-craft/tools/a11y-checklist.md`
5. **Record** results into `ui-review.md` (or session summary with paths to screenshots).
6. **Stop** — hand fixes to Lane B; re-verify after fixes.

## Guardrails

- Don't claim visual OK without opening the app (or explicit user waiver).
- Bounded fix loop for UI bugs still ≤3 then ask (`docs/workflows/recommended.md`).
- No push/PR from this skill.
