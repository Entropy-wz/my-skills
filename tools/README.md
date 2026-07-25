# Tools

**Cross-kit shared utilities** — scripts and small CLIs reused by more than one kit or skill.

Kit-specific tools stay under `kits/<name>/tools/`. Put something here only when a second consumer needs it.

## run-gates

Discover and run a repo's local quality gates; emit paste-ready Verification markdown.

```powershell
./tools/run-gates.ps1 [-Path <repo>] [-Json] [-DryRun] [-TimeoutSec 900]
# macOS / Linux (delegates to .ps1 when PowerShell exists):
./tools/run-gates.sh [-Path <repo>] [-Json] [-DryRun]
```

| Flag | Meaning |
| --- | --- |
| `-Path` | Repo root to scan (no `.git` walk when set). Omit to walk up from cwd. |
| `-DryRun` | Print planned commands; do not execute. |
| `-Json` | Also print a one-line JSON summary after the Markdown. |
| `-TimeoutSec` | Per-command timeout (default 900). |

| Exit | Meaning |
| --- | --- |
| 0 | All ran gates passed |
| 1 | At least one gate failed (or timed out) |
| 2 | Runtime missing (e.g. npm/make/bash) |
| 4 | No gates discovered |

Discovery order: `scripts/gates.ps1` / `gates.sh` (sole runner if present) → `package.json` `lint`/`typecheck`/`test` → Makefile `lint`/`test`/`check` → `scripts/check-layout.ps1`.

### Resolving from an installed skill (`ship-gate`)

1. `<target-repo>/tools/run-gates.ps1` if present  
2. `$env:MY_SKILLS_ROOT/tools/run-gates.ps1`  
3. Ask the user for their my-skills checkout path  

Set once per shell (example):

```powershell
$env:MY_SKILLS_ROOT = "C:\Users\lenovo\my-skills"
```

No automatic install of `tools/` into `~/.cursor/skills` yet — call by path or via `MY_SKILLS_ROOT`.
