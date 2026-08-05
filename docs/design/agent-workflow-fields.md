# Workflow fields checklist

Phase 2 formal schema lives at
[`kits/agent-flow-studio/schema/workflow.schema.json`](../../kits/agent-flow-studio/schema/workflow.schema.json)
(authored in Lane B). Disk format: **YAML** validated with that JSON Schema ([ADR-003](../adr/003-workflow-yaml-as-studio-sot.md)).

> **Note:** Lives under `docs/design/` (not `docs/agents/`) so it does not collide with
> work-lanes’ mattpocock-style `docs/agents/` process docs.

## Checklist (aligned with studio v1)

- [x] `id` — stable workflow identifier (**must equal** folder `<name>`)
- [x] `name` — human title
- [x] `version` — workflow schema version string (`"1"` in v1)
- [x] `nodes[]` — each node:
  - [x] `type` ∈ { `step`, `skill`, `gate` } (**accepted in v1**)
  - [ ] `type` ∈ { `agent`, `human` } — **reserved**; rejected by studio validation until later
  - [x] `ref` — skill leaf or gate id (for `skill` / `gate`)
  - [x] `label`, optional `notes` / `inputs`
- [x] `edges[]` — each edge:
  - [x] `from` / `to` — node ids
  - [x] `condition` (optional) — **stored label only** in v1 (not executed)
- [x] `defaults` — effort, fixed-point, …
- [x] `banned_actions` — e.g. `push`, `pr_create`, `issue_create`
- [x] `summary`, `when[]`, `when_not[]`, `inputs[]`, `outputs[]`, optional `prompt`

## Related

- ADR-002: `docs/adr/002-agents-as-role-packs.md`
- ADR-003: `docs/adr/003-workflow-yaml-as-studio-sot.md`
- Design: `docs/design/2026-07-27-agent-flow-studio.md`
- Demo pack (hand-authored AGENT.md; migrate YAML-only under D1): `agents/ship-review/`
