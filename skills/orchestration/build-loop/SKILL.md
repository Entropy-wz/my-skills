---
name: build-loop
description: Thin workflow entry — load the skill-local workflows/recommended.md menu, match the user's intent to a recommended skill chain, and tell them which skills to invoke next. Does not implement, test-loop, or ship. Trigger phrases — "build-loop", "/build-loop", "recommended workflow", "what workflow", "推荐工作流", "该走哪条链", "工作流菜单".
disable-model-invocation: true
---

# Build Loop (workflow menu)

**Thin entry only.** This skill no longer orchestrates frame → implement → test → review.
It opens the recommended-workflow menu and matches intent to a skill chain.

## Menu file (required — skill-local)

Resolve **from this skill directory** (works after install into `~/.cursor/skills/build-loop/`):

| File | Role |
| --- | --- |
| [`workflows/recommended.md`](workflows/recommended.md) | Authoritative workflow menu |

Fallback if the link fails: ask for `MY_SKILLS_ROOT` and read
`skills/orchestration/build-loop/workflows/recommended.md` under that checkout.

Human-readable mirror (may lag): `docs/workflows/recommended.md` in the my-skills repo —
**agents must prefer the skill-local file**, same pattern as `research-case-card` templates.

If the menu file is missing even after fallback, say so and stop — do not invent chains.

## When to use / when not

Use when the user asks which workflow to follow, says `/build-loop`, or wants a
menu of recommended skill chains.

Don't use when:
- They already named a concrete skill (`/ship-gate`, `/work-lanes`, …) → invoke that skill.
- They only want a review → `merge-code-review` / `code-review`.
- They are deciding push / issue / PR → `work-lanes`.

## Flow

1. **Load** `workflows/recommended.md` from this skill directory (full file).
2. **Match** the user's intent to exactly one workflow row (feature, bug, multi-task,
   docs, frontend, incident, pre-ship, architecture, …). If ambiguous, present the
   two closest rows and ask.
3. **Report** the chain: ordered skill names, lane notes, and any `（planned Wave N）`
   items still unavailable.
4. **Hand off** — tell the user (or invoke, if they ask) the **next existing** skill
   in the chain. Skip planned items or note the interim fallback written in the menu.
5. **Stop.** Do not implement the work inside this skill.

## Guardrails

- **Never** re-run the old orchestrator (frame → propose → implement → test → review).
- **Never** substitute for `clarify-and-plan`, `systematic-debugging`, `multi-task-protocol`,
  or other skills named in the menu — only point at them.
- **Never** `git push`, open PRs, or create issues — that belongs to `work-lanes`.
- Respect shared discipline in the menu: bounded fix retries ≤3, evidence before "done".
- If a chain step is `（planned）`, do not pretend the skill exists.

## Boundaries vs other skills

| Skill | Role |
| --- | --- |
| `build-loop` (this) | Menu + match + handoff only |
| `work-lanes` | Lanes + remote outbox |
| `ship-gate` | Pre-ship gates + merge-code-review |
| Concrete skills in the menu | Do the real work |

## Example invocations

- "/build-loop I need to add rate limiting — which chain?"
- "推荐工作流：这是个线上事故"
- "what workflow for a merge-ready bug fix?"
