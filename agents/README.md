# Agents

**Non-install role packs** — reusable multi-step scripts (purpose, steps, handoffs, bans).  
See **[ADR-002](../docs/adr/002-agents-as-role-packs.md)** and the design  
[`docs/design/2026-07-27-agents-layer-and-ship-review.md`](../docs/design/2026-07-27-agents-layer-and-ship-review.md).

## Agent vs skill vs kit

| Layer | Role | Install? |
| --- | --- | --- |
| **Agent** (`agents/<name>/`) | Editorial **source of truth** for a role pack | **No** — never discovered by `install.ps1` / `install.sh` |
| **Thin skill** (`skills/orchestration/<name>/`) | Cursor `/name` trigger; loads the pack | **Yes** — leaf install name |
| **Kit** | Runnable assets (scripts, docker, …) | Optional `skill/`; must not dual-SKILL the same name |

Kit-local helpers may still live under `kits/<name>/agents/`. Top-level `agents/` is for shared role packs.

## Sync rule (copy-install)

1. Edit **`agents/<name>/`** first (`AGENT.md`, optional `prompt.md`).
2. Copy verbatim into **`skills/orchestration/<name>/agent/`**.
3. Never hand-edit the snapshot alone. `check-layout` requires **byte-identical** file set + content.

The thin skill reads `./agent/AGENT.md` relative to the installed skill dir (works for symlink and `-Copy`).

## When to create an agent

- Multi-step **role** that several sessions reuse, and you want `/name` without stuffing a long skill.
- Steps mostly **handoff** to existing skills (e.g. `ship-gate`, `merge-code-review`).

Do **not** create an agent for a single short skill, or for assets that belong in a kit.

## Layout

```
agents/
  README.md          # this file
  _template/         # copy to agents/<name>/ (skipped by mirror CI — `_` prefix)
  ship-review/       # demo: outbound review script
```

Future workflow field checklist (no schema yet): [`docs/design/agent-workflow-fields.md`](../docs/design/agent-workflow-fields.md).
