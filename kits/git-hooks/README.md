# Kit: git-hooks

Local **pre-commit** hygiene + **guardrails** against destructive git on `main`/`master`.  
This is **not** a substitute for `ship-gate` / `run-gates` (outbound). Layers:

| Layer | When |
| --- | --- |
| `kits/git-hooks` | Before `git commit` / risky `git push` on a machine |
| `ship-gate` | Before push/PR "done" claim |

Hook scripts are forced **LF** via `.gitattributes` (`eol=lf`) so shebangs work with `core.autocrlf`.

## Prerequisites

- Git repo target
- Writable `core.hooksPath` (install sets `.githooks` in the target repo)

## Quick start

```powershell
# from my-skills root — install hooks into TARGET repo
powershell -File kits/git-hooks/tools/install.ps1 -Path D:\path\to\repo
# if husky/lefthook already owns hooksPath:
powershell -File kits/git-hooks/tools/install.ps1 -Path D:\path\to\repo -Force
```

```bash
bash kits/git-hooks/tools/install.sh /path/to/repo
bash kits/git-hooks/tools/install.sh --force /path/to/repo
```

## What gets installed

Target repo gains `.githooks/`:

- `pre-commit` — blocks staged diffs that look like secrets (expanded patterns); reminds Conventional Commits
- `pre-push` — blocks **non-FF** and **delete** of `refs/heads/main` or `refs/heads/master` unless `GIT_HOOKS_ALLOW_FORCE=1`

Install refuses to clobber an existing `core.hooksPath` unless `-Force` / `--force`.

## Layout

| Path | Role |
| --- | --- |
| `tools/install.ps1` / `install.sh` | Copy hooks + set `core.hooksPath` (fail if git config fails) |
| `hooks/pre-commit` | Shared pre-commit (LF) |
| `hooks/pre-push` | Shared pre-push guardrail (LF) |

No `skill/SKILL.md` — document-only kit; agents read this README when user asks for hooks.
