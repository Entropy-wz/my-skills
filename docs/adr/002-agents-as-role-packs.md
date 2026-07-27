# ADR-002: Agents as non-install role packs with thin skill mirrors

## Status

Accepted

## Date

2026-07-27

## Context

Top-level `agents/` is empty while the README promises small agents. Process orchestration already lives in skills (`ship-gate`, `work-lanes`, …). We need agents without inventing a fourth **install** kind that would conflict with ADR-001 (skills / kits / tools only).

Users want `/name` invocation in Cursor, which requires a `SKILL.md` install surface. A later in-repo visual studio (`kits/agent-flow-studio`) should generate role packs, not a new runtime installer.

## Options Considered

### Option A: `agents/` source of truth + thin `skills/orchestration/<name>/` mirror

- Pros: Clear SoT; `/name` works; studio can target `agents/`; ADR-001 install kinds unchanged
- Cons: Mirror drift risk; need CI or sync rule

### Option B: Kit-only agents (`kits/<name>/agents/`), no top-level packs

- Pros: Fits kit=assets
- Cons: Cross-kit reuse weak; top-level `agents/` stays hollow

### Option C: Docs-only agents (no skill mirror)

- Pros: Cheapest
- Cons: No `/name` trigger; fails stated Phase 1 invocation need

## Decision

We choose **Option A**.

1. An **agent** is a reusable multi-step **role pack** under `agents/<name>/` (`AGENT.md`, optional `prompt.md`). It is **not** discovered by `install.ps1` / `install.sh`.
2. Invocation uses a **thin skill mirror** at `skills/orchestration/<name>/SKILL.md` (install name = leaf). The skill points at a skill-local `./agent/` snapshot (e.g. `agent/AGENT.md`); it must not own a second full copy of the steps as the editorial SoT.
3. For **copy-install** into `~/.cursor/skills/<name>/`, the thin skill directory **must** carry a synced `agent/` snapshot of the pack; CI enforces recursive equality with `agents/<name>/`. Editorial edits happen in `agents/` first, then sync.
4. Kits must not expose `skill/SKILL.md` under the same install name as an agent mirror (ADR-001 dual-SKILL ban).
5. Phase 2 studio generates/updates `agents/` (and syncs mirrors); it does not add an `agents` install kind.

## Consequences

- Update `agents/README.md`, templates, and `check-layout` mirror contract.
- Demo agent: `ship-review` (outbound review script; handoff to `ship-gate` when gates needed).
- Future schema fields listed in `docs/design/agent-workflow-fields.md` (no format locked here).
- Links: `docs/design/2026-07-27-agents-layer-and-ship-review.md`; plan `docs/design/plans/2026-07-27-agents-layer-and-ship-review.md`.
- Accepted by maintainer 2026-07-27.
