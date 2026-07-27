---
name: skill-fit
description: Fit existing skills and kits to this repo — template alignment, handoffs, triggers, dedupe; includes skill-gardening patterns and a lightweight skill-scanner checklist. Trigger phrases — "skill-fit", "贴合仓库", "skill-gardening", "扫描 skills 安全", "skill-scanner".
disable-model-invocation: true
---

# Skill Fit

Make **existing** skills and kits fit `my-skills` conventions. Not a from-scratch "write skills
with TDD" course (that was upstream `writing-skills`).

## When to use / when not

Use when adding/editing skills, after intake waves, or before releasing skill changes.

Don't use for application feature work unrelated to the toolkit.

## Fit checklist (per skill/kit)

- [ ] Frontmatter: `name`, `description` (triggers), `disable-model-invocation` when orchestration
- [ ] Matches `skills/_template` shape: when to use / not, steps, guardrails
- [ ] Handoff one-liner to `work-lanes` / `ship-gate` / workflow menu where relevant
- [ ] Paths match repo (`docs/design/`, `docs/adr/`, `docs/workflows/recommended.md`)
- [ ] No duplicate of another skill's job (dedupe or cross-link)
- [ ] Listed in `skills/orchestration/build-loop/workflows/recommended.md` if it is a menu entry
- [ ] `scripts/check-layout.ps1` still passes after installable changes
- [ ] `scripts/scan-skills.ps1` clean (or findings explained)

## Skill-gardening (section)

When the user repeatedly corrects the same convention or repeats a multi-step flow:

1. **Suggest a Cursor rule** (`.cursor/rules`) for stable conventions.
2. **Draft a new skill** under `skills/<category>/<leaf>/` from the repeated flow (ask before writing; see ADR-001).
3. Prefer thin skills that point at kits for runnable assets.

## Skill-scanner (lightweight, runnable)

From my-skills root:

```powershell
powershell -NoProfile -File scripts/scan-skills.ps1
```

Exit `1` on Critical pattern hits. Also manually skim for:

- [ ] Instructions to leak credentials / env / private data to third parties
- [ ] Prompt-injection style “disregard prior instructions” patterns
- [ ] Unbounded download-and-run via shell pipe without user confirmation
- [ ] Hidden steps that force-push or rewrite git identity config
- [ ] Claims that override `work-lanes` remote gates

This is **not** a full Sentry skill-scanner port — grep gates only.

## Guardrails

- Prefer edit-in-place over proliferating near-duplicate skills.
- No remote ship from this skill.
