# Tools

**Cross-kit shared utilities** — scripts and small CLIs reused by more than one kit or skill.

Kit-specific tools stay under `kits/<name>/tools/`. Put something here only when a second consumer needs it.

No install step yet; call tools by path from skills/agents (e.g. `tools/foo.ps1`).
