---
name: hunk-walkthrough
description: Steer a live Hunk terminal diff session — launch Hunk if needed, then list/get/review/navigate/reload via `hunk session`, narrate findings in chat. No inline comments. Use when the user asks to walk a diff in Hunk or review with Hunk.
---

# Hunk walkthrough (no comments)

Hunk is a review-first terminal diff viewer. Drive a **live** window with
`hunk session *` through the local daemon. Narrate findings **in chat**.

**This skill never adds, applies, lists, removes, or clears Hunk comments.**
Do not run `hunk session comment …` or `--next-comment` / `--prev-comment`.

## Launch (agent may open Hunk)

If `hunk session list` shows no session for the target repo, **the agent should
start Hunk itself** in a separate terminal/console (do not block the agent TTY
on the interactive TUI):

```powershell
# Windows — new console so the TUI has a real PTY
Start-Process cmd.exe -ArgumentList '/c','hunk diff origin/main...HEAD' -WorkingDirectory <repo>

# Or: hunk show / hunk diff <other-range>
```

```bash
# macOS / Linux — new terminal tab/window when available, else background + note
hunk diff origin/main...HEAD
```

Then wait briefly and re-run `hunk session list`. Prefer scoping later commands
with `--repo <repoRoot>` or the `sessionId`.

Requires `hunk` on PATH (`npm i -g hunkdiff`). If install is missing, install or
tell the user once — then launch.

## Session commands (read-only subset)

```bash
hunk session list [--json]
hunk session get (--repo . | <id>) [--json]
hunk session context (--repo . | <id>) [--json]
hunk session review (--repo . | <id>) [--json] [--include-patch]
```

Navigate — `--file` plus exactly one of `--hunk` / `--new-line` / `--old-line`:

```bash
hunk session navigate --repo . --file <path> --hunk <n>
hunk session navigate --repo . --file <path> --new-line <n>
```

Reload:

```bash
hunk session reload --repo . -- diff
hunk session reload --repo . -- diff origin/main...HEAD
hunk session reload --repo . -- show HEAD~1
```

## Workflow

1. `hunk session list` — if empty for this repo, **launch Hunk** (see above), then list again.
2. `hunk session review --repo . --json` — file/hunk structure first.
3. `--include-patch` only when raw diff text is needed.
4. `navigate` / `context` while discussing specific hunks.
5. Narrate findings in chat. Never write comments into the session.
