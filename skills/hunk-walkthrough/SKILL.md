---
name: hunk-walkthrough
description: Steer a live Hunk terminal diff session — list/get/review/navigate/reload via `hunk session`, narrate findings in chat. No inline comments. Use when the user has Hunk open or asks to walk a diff in Hunk.
---

# Hunk walkthrough (no comments)

Hunk is an interactive terminal diff viewer. The TUI is for the user — **do NOT** run
`hunk diff`, `hunk show`, or other interactive TUI commands yourself. Drive the live
window with `hunk session *` through the local daemon.

**This skill never adds, applies, lists, removes, or clears Hunk comments.** Findings
and narration go in the chat. Do not run `hunk session comment …` or
`--next-comment` / `--prev-comment`.

If no session exists, ask the user to launch Hunk in their terminal first, e.g.:

```bash
hunk diff
hunk show
hunk diff origin/main...HEAD
```

## Session commands (read-only subset)

Scope with `--repo .` (or a `<session-id>`) when multiple sessions are open. Never touch
any `comment` subcommand.

```bash
hunk session list [--json]                                 # find live sessions
hunk session get (--repo . | <id>) [--json]                # path / repo / source
hunk session context (--repo . | <id>) [--json]            # current focus
hunk session review (--repo . | <id>) [--json] [--include-patch]   # file/hunk structure
```

Navigate — absolute nav needs `--file` plus exactly one of `--hunk` / `--new-line` /
`--old-line`:

```bash
hunk session navigate --repo . --file <path> --hunk <n>
hunk session navigate --repo . --file <path> --new-line <n>
```

Reload swaps the live session's contents — pass a Hunk review command after `--`:

```bash
hunk session reload --repo . -- diff
hunk session reload --repo . -- diff main...feature -- src/ui
hunk session reload --repo . -- show HEAD~1
```

## Workflow

1. `hunk session list` — confirm a session exists (else ask the user to launch Hunk).
2. `hunk session review --repo . --json` — inspect file/hunk structure first.
3. Add `--include-patch` only when you actually need the raw diff text.
4. `hunk session context` / `navigate …` — move to the hunk you're discussing.
5. `hunk session reload -- <command>` — swap contents if the user wants a different diff.
6. Narrate every finding **in chat**. Never write comments into the session.
