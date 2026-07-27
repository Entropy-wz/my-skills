# Workflow fields checklist (Phase 2 prep)

**Not a schema.** Format (YAML/JSON/…) is **TBD in Phase 2** (`kits/agent-flow-studio`).  
This checklist lists fields a future exporter must cover so role packs and graphs stay aligned with ADR-002.

> **Note:** Lives under `docs/design/` (not `docs/agents/`) so it does not collide with
> work-lanes’ mattpocock-style `docs/agents/` process docs.

## Checklist

- [ ] `id` — stable workflow identifier  
- [ ] `name` — human title  
- [ ] `nodes[]` — each node:
  - [ ] `type` ∈ { `skill`, `agent`, `gate`, `human` }
  - [ ] `ref` — skill leaf, agent name, gate id, or prompt key  
  - [ ] `inputs` — declared inputs for the node  
- [ ] `edges[]` — each edge:
  - [ ] `from` / `to` — node ids  
  - [ ] `condition` (optional) — when the edge is taken  
- [ ] `defaults` — effort, fixed-point, timeouts, …  
- [ ] `banned_actions` — e.g. `push`, `pr_create`, `issue_create`  

## Related

- ADR-002: `docs/adr/002-agents-as-role-packs.md`  
- Design: `docs/design/2026-07-27-agents-layer-and-ship-review.md`  
- Demo pack: `agents/ship-review/`  
