---
name: using-git-worktrees
description: Ensure an isolated git worktree (or Cursor native isolation) before long plans, parallel approaches, or dirty-main work. Not required for every commit. Trigger phrases — "using-git-worktrees", "git worktree", "隔离工作区", "worktree".
disable-model-invocation: true
---

# Using Git Worktrees

## When to use / when not

Use when:

- Starting a long plan / multi-task execution
- Trying parallel approaches (best-of-n style)
- Main working tree is dirty with unrelated work

**Not** default for every small commit.

Don't use when already inside a dedicated worktree/branch isolation you verified.

## Flow

1. **Detect existing isolation** — path looks like a linked worktree?
   `git rev-parse --git-dir` / `git worktree list`. If already isolated for this task, reuse.
2. **Prefer native** — Cursor best-of-n / native worktree tools when the user wants parallel
   attempts in-product.
3. **Fallback** — `git worktree add <path> -b <branch>` from a clean base (`main`/`master`).
4. **Work only in that path** for the task; tell the user the path.
5. **Cleanup** (when user asks) — remove worktree after merge/abandon:
   `git worktree remove <path>` (never delete a worktree with unpushed needed work without asking).

## Optional hard-problem mode

When the user wants multiple competing implementations: one worktree (or native isolate)
per approach → compare → pick winner → discard losers. Announce "hard-problem mode".

## Guardrails

- Never disrupt the user's unrelated dirty files in the primary tree without asking.
- Branch naming still follows `work-lanes` hygiene when commits are made.
- No push from this skill.
