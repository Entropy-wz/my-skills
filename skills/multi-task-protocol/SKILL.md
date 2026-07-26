---
name: multi-task-protocol
description: Execute a written multi-task plan with fresh subagents per task, a task-level review after each, and one wide branch review at the end. Lane B only — no remote. Trigger phrases — "multi-task-protocol", "按计划派子代理", "subagent per task", "多任务执行协议".
disable-model-invocation: true
---

# Multi-Task Protocol

Run an **already written** implementation plan as parallelizable or sequential tasks with
isolated implementers and reviews. Inspired by Superpowers subagent-driven development;
short production protocol for this toolkit.

## When to use / when not

Use when:

- There is a written plan (`docs/design/plans/*` or equivalent) with multiple tasks
- Tasks can be described without sharing a single muddy context

Don't use when:

- Single-task / small change → just implement under Lane B
- No plan yet → `clarify-and-plan` first
- Need push/PR → finish here, then `ship-gate` + `work-lanes` Lane C

## Protocol

1. **Load plan** — list tasks; note dependencies. Do not invent scope.
2. **Confirm Lane B** — no remote actions in this skill.
3. **Per task:**
   - Dispatch a **fresh** subagent (or equivalent isolated context) with only what that
     task needs — do not dump the whole parent chat.
   - Implementer finishes the task (tests for that slice when applicable).
   - **Task review** (read-only): spec compliance + obvious quality issues. Fix blockers
     before the next task.
4. **Continue** without "should I continue?" prompts. Stop only on BLOCKED, true ambiguity,
   or all tasks done.
5. **Final review** — wide diff / whole-branch: invoke `merge-code-review` (or `code-review`
   if the user wants teaching axes).
6. **Stop** — summarize; hand ship to `ship-gate` / Lane C if requested.

## Bounded fixes

Per-task test failures: retry fixes at most **3** times (see `docs/workflows/recommended.md`),
then BLOCKED + ask. Do not infinite-loop.

## Guardrails

- Requires a written plan — no plan, no protocol.
- Never touch remote (`push`, `gh pr`, `gh issue`).
- Fresh context per task; parent coordinates only.
- Task review after each task; final wide review once at end.
