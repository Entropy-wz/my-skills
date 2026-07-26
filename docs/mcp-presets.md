# MCP presets (documentation only)

MCP servers are installed in **Cursor settings** on each machine — this repo does **not**
vendor MCP server source. Skills = procedures; Kits = runnable local deps; MCP = sockets
to external systems.

## Skill vs Kit vs MCP

| Need | Prefer |
| --- | --- |
| Process / gates / review | `skills/` |
| Docker/CLI wrappers (SearXNG, hooks, frontend assets) | `kits/` |
| Live SaaS (Figma, Linear, Slack, Datadog…) | Official Cursor Marketplace MCP / plugin |

## Recommended (install when you actually need them)

| Server / plugin | Why | Permissions note |
| --- | --- | --- |
| Cursor app-control | Workspace switch / project helpers | Local IDE control |
| Figma | Design-to-code | Read design files you authorize |
| Linear | Issues/projects | Prefer read-only until write needed |
| Slack | Channel search / posts | Narrow channels; careful with write |
| Sentry | Errors / perf | Org token scoped |
| Datadog | Logs/metrics | Read-only keys when possible |
| GitHub (gh CLI) | Often enough **without** MCP | Use `gh` from Shell under work-lanes |

Env var names vary by server — copy from each plugin's docs into a **local** `.env` that
is gitignored. Never commit tokens.

## Self-hosted bridge (future)

SearXNG stays a **kit** (`kits/searxng-search`). A thin MCP wrapper is optional later —
not required for agents that can run `search.ps1`.

## Security

- Prefer official Marketplace listings.
- Minimum scopes; revoke unused tokens.
- Untrusted third-party MCP = untrusted code execution.
- Skill text risks: run `skill-fit` scanner checklist on `skills/**`.

## Optional: Superpowers plugin (C)

For a heavy methodology mode in Cursor: install Superpowers from the marketplace
(`/add-plugin superpowers` or equivalent). This toolkit **does not** vendor those skills;
we absorbed selected ideas into `clarify-and-plan`, `systematic-debugging`, etc.
Do not enable both "must auto-invoke all Superpowers" and our explicit-trigger skills
without expecting conflict — pick a mode per session.
