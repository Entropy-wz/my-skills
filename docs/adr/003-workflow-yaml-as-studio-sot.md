# ADR-003: Dual SoT — workflow.yaml for studio-managed agents

## Status

Accepted

## Date

2026-07-27

## Context

[ADR-002](002-agents-as-role-packs.md) makes `agents/<name>/` the role-pack home and
`AGENT.md` the human/executable script, with a recursive snapshot under
`skills/orchestration/<name>/agent/`.

Phase 2 [`agent-flow-studio`](../design/2026-07-27-agent-flow-studio.md) edits packs as
graphs. Graph editors need a structured sidecar; naively regenerating `AGENT.md` on every
save would destroy carefully authored demos (e.g. `ship-review`).

We need a clear rule for what is authoritative when both YAML and Markdown exist, without
adding a new install kind.

## Options Considered

### Option A: Dual regime (chosen)

- With `workflow.yaml` → YAML is orchestration SoT; `AGENT.md` is generated.
- Without → `AGENT.md` remains hand-authored SoT.
- Snapshot equality still covers the whole directory tree.

### Option B: Always YAML; migrate all agents immediately

- Pros: One rule.
- Cons: Forces lossy rewrite of `ship-review` before the generator is proven.

### Option C: AGENT.md always SoT; YAML is layout cache only

- Pros: Preserves prose.
- Cons: Conflicts with graph-primary editing; round-trips stay lossy forever.

## Decision

Choose **Option A**.

1. **Studio-managed pack:** `agents/<name>/workflow.yaml` is the orchestration source of
   truth. On save, the studio validates (JSON Schema), writes YAML, regenerates `AGENT.md`,
   optionally writes `prompt.md`, then **recursively mirrors and prunes** into
   `skills/orchestration/<name>/agent/`, and ensures a thin `SKILL.md` exists.
2. **Hand-authored pack:** absence of `workflow.yaml` means `AGENT.md` remains SoT.
   Migrate may create YAML from Markdown **without** rewriting `AGENT.md` (D1 for
   `ship-review`).
3. Disk format: YAML + `kits/agent-flow-studio/schema/workflow.schema.json`.
4. Kit `kits/agent-flow-studio/` holds UI/server/schema assets. It must **not** ship
   `skill/SKILL.md` with install leaf `agent-flow-studio` — that leaf is reserved for the
   orchestration launch skill added in Lane B (ADR-001 dual-SKILL ban).
5. No fourth install kind: installers still ignore `agents/`.

## Consequences

- Amend ADR-002 Consequences to point here for studio-managed packs.
- Update `agents/README.md` sync rule to mirror **all** files (including `workflow.yaml`).
- Update `docs/design/agent-workflow-fields.md` for v1 node types (`step|skill|gate`).
- Acceptance for studio v1 uses a graph-first fixture; `ship-review` migrate is read-only
  w.r.t. `AGENT.md`.
- Accepted by maintainer 2026-07-27 (D1 accepted).
