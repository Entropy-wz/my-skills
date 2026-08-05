# Agents

**Non-install role packs** — reusable multi-step scripts (purpose, steps, handoffs, bans).  
See **[ADR-002](../docs/adr/002-agents-as-role-packs.md)**, **[ADR-003](../docs/adr/003-workflow-yaml-as-studio-sot.md)**
(studio dual-SoT), and designs  
[`2026-07-27-agents-layer-and-ship-review.md`](../docs/design/2026-07-27-agents-layer-and-ship-review.md),  
[`2026-07-27-agent-flow-studio.md`](../docs/design/2026-07-27-agent-flow-studio.md).

## Agent vs skill vs kit

| Layer | Role | Install? |
| --- | --- | --- |
| **Agent** (`agents/<name>/`) | Role pack home (see SoT regime below) | **No** — never discovered by `install.ps1` / `install.sh` |
| **Thin skill** (`skills/orchestration/<name>/`) | Cursor `/name` trigger; loads `./agent/` snapshot | **Yes** — leaf install name |
| **Kit** | Runnable assets (scripts, docker, studio UI, …) | Optional `skill/`; must not dual-SKILL the same name |

Kit-local helpers may still live under `kits/<name>/agents/`. Top-level `agents/` is for shared role packs.

## Source-of-truth regime (ADR-003)

| Pack state | Orchestration SoT | `AGENT.md` |
| --- | --- | --- |
| Has `workflow.yaml` | YAML (studio-managed) | Generated on save — do not hand-edit |
| No `workflow.yaml` | — | Hand-authored SoT (e.g. `ship-review` today) |

Studio migrate may create `workflow.yaml` from Markdown **without** rewriting `AGENT.md` (D1).

## Sync rule (copy-install / check-layout)

1. Edit the authoritative side first (YAML if present, else `AGENT.md` / pack files).
2. Copy **the entire** `agents/<name>/` tree verbatim into
   `skills/orchestration/<name>/agent/` (includes `AGENT.md`, optional `prompt.md`,
   **`workflow.yaml`**, and any other files). Mirror **and prune** extras on the snapshot side.
3. Never hand-edit the snapshot alone. `check-layout` requires **byte-identical** recursive
   file set + content.

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
  ship-review/       # demo: outbound review script (hand-authored AGENT.md)
```

Workflow fields / schema pointer: [`docs/design/agent-workflow-fields.md`](../docs/design/agent-workflow-fields.md).  
Visual editor (Phase 2): `kits/agent-flow-studio/` + `/agent-flow-studio` launch skill.
