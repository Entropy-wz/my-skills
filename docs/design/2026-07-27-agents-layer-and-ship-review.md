# Agents layer + ship-review demo (and Phase 2 studio sketch)

**Status:** Approved (Lane A / clarify-and-plan)  
**Date:** 2026-07-27  
**Repo:** my-skills  
**Related:** ADR-001; ADR-002 (Accepted); plan `docs/design/plans/2026-07-27-agents-layer-and-ship-review.md`

## Why

`agents/` is an empty stub while README promises “small Agents.” Skills already own process orchestration (`work-lanes`, `ship-gate`, `multi-task-protocol`). We need a clear **agent** concept that:

1. Fills the gap with conventions + a minimal demo (not a second runtime).
2. Stays compatible with ADR-001 (skills / kits / tools only as *install* kinds).
3. Leaves a clean target for a later in-repo visual workflow studio.

## Goals (Phase 1)

- Document agent vs skill vs kit boundaries.
- Add `agents/_template` + one thin demo: **ship-review** (outbound / merge-readiness script).
- Mirror demo as `skills/orchestration/ship-review` for `/ship-review` invocation.
- Document a **field checklist** for a future workflow schema (no formal YAML/JSON yet).
- Optional CI: agent ↔ thin-skill mirror consistency.

## Non-goals (Phase 1)

- Flowchart UI, codegen backend, or formal workflow file format.
- New install discovery kind for `agents/`.
- Replacing `ship-gate` or `work-lanes`.
- `modules/` / `plugins/`.
- Full-strength review automation beyond pointing at existing skills.

## Decisions locked in clarify

| Topic | Choice |
| --- | --- |
| Scope | Phased: conventions + demo first; visual studio later |
| Phase 1 success | Docs + templates primary; minimal demo (prompt + README/AGENT) |
| Demo domain | Review / outbound (`merge-code-review` / handoff to `ship-gate`) |
| Invocation | `agents/` = source of truth; thin skill mirror for `/name` |
| Studio home | Same repo: future `kits/agent-flow-studio/` + skill entry |
| Schema | Phase 1 = field checklist only (`docs/design/agent-workflow-fields.md`) |

## Approach (chosen: A)

**`agents/<name>/` is source of truth; `skills/orchestration/<name>/SKILL.md` is a thin trigger** that loads the skill-local `./agent/` snapshot. Kits may hold runnable assets later; they must not ship a same-named `skill/SKILL.md` (ADR-001 dual-SKILL ban).

Rejected for Phase 1:

- **B** — everything only under a kit (leaves top-level `agents/` empty; weak cross-kit story).
- **C** — docs-only with no installable trigger (conflicts with `/ship-review` requirement).

## Boundaries

| Concept | Role | Install surface |
| --- | --- | --- |
| Skill | Process / orchestration entry (`SKILL.md`) | `~/.cursor/skills/<leaf>/` |
| Kit | Runnable multi-part assets | Optional `kits/<name>/skill/`; asset-only OK |
| Agent | Reusable multi-step **role pack** (purpose, steps, handoffs, bans) | **Not** installed directly |
| Thin skill mirror | Trigger only: Read `./agent/` snapshot (SoT = `agents/<name>/`) | Same leaf name under `skills/orchestration/<name>/` |

Hard rules:

1. Source of truth = `agents/<name>/`. Thin skills must not duplicate long step prose.
2. No `kits/<name>/skill/SKILL.md` colliding with `skills/**/<name>/` (ADR-001).
3. `agents/**` is never an install discovery source for `install.ps1` / `install.sh`.
4. Phase 2 studio generates/updates `agents/` (and may propose thin-skill sync), not a fourth runtime.

## Layout (Phase 1)

```
agents/
  README.md
  _template/
    AGENT.md
    prompt.md
  ship-review/
    AGENT.md
    prompt.md
skills/orchestration/ship-review/
  SKILL.md          # thin entry → ./agent/
  agent/            # synced snapshot of agents/ship-review/
docs/design/
  agent-workflow-fields.md
```

## Demo: `ship-review`

### Positioning

Outbound **review script** pack. Does not reimplement gate running.

| | `ship-gate` | `ship-review` |
| --- | --- | --- |
| Primary job | Discover/run gates → Verification → hand off review | Merge-readiness script: fixed-point, effort, report skeleton |
| Remote | Forbids push/PR/issues | Same |
| Relationship | Can be a handoff target from the agent | Thin `/ship-review` loads skill-local `./agent/` (SoT `agents/ship-review/`); steps say when to switch to `/ship-gate` |

### Minimal steps (`AGENT.md`)

1. Confirm fixed-point (default `origin/main`) and effort (default medium).
2. Build scope: three-dot commits **plus** dirty WT; always **Read** untracked (`??`) bodies. If three-dot is empty and `HEAD ==` fixed-point → WT-only (do not stop). If `HEAD` is behind the fixed-point → warn / catch up; do not review the full two-dot “delete remote” diff.
3. If the user also wants gates → **handoff** to `/ship-gate` (do not re-encode `run-gates` here).
4. Otherwise follow `merge-code-review` on that scope and emit the report skeleton (Critical / Important / Spec / Verification suggested).
5. Stop: remind that Lane C shipping remains `work-lanes`.

### Thin skill mirror

`skills/orchestration/ship-review/SKILL.md`:

- Frontmatter `name: ship-review` + triggers (`/ship-review`, 出站审查, etc.).
- Body: point only at **skill-local** [`./agent/AGENT.md`](../../skills/orchestration/ship-review/agent/AGENT.md) (+ `prompt.md` if present); execute; do **not** duplicate Boundaries/Steps; do **not** require live `agents/` at install time.
- Contributor SoT remains `agents/ship-review/`; sync into `skills/orchestration/ship-review/agent/` before commit. `check-layout` enforces recursive hash equality.

## Templates

`agents/_template/AGENT.md` sections:

- Purpose  
- When / When not  
- Steps  
- Handoffs (skills/kits by name)  
- Boundaries (banned actions)  
- Inputs / Outputs  

Optional `prompt.md`: model-facing prose kept out of the thin skill.

## Future workflow fields (checklist only)

`docs/design/agent-workflow-fields.md` lists fields Phase 2 must cover, without choosing YAML vs JSON:

- `id`, `name`  
- `nodes[]`: `type` ∈ {skill, agent, gate, human}, `ref`, `inputs`  
- `edges[]`: `from`, `to`, optional `condition`  
- `defaults`  
- `banned_actions` (e.g. push, PR, issue create)

## CI / consistency (Phase 1)

- `check-layout` must **not** treat `agents/**` as installable skills.
- Recommended contract: every `agents/<name>/AGENT.md` (skip `_…`) has matching `skills/orchestration/<name>/SKILL.md` whose body references `agent/AGENT.md`, plus a recursively equal `agent/` snapshot.
- `scan-skills` continues to scan SKILL.md only (mirrors stay short).

## Phase 2 sketch (out of Phase 1 implementation)

- Kit: `kits/agent-flow-studio/` — flowchart UI assets + export tooling.  
- Skill entry: thin orchestration skill pointing at the kit.  
- Export/update target: `agents/<name>/` (+ optional thin-skill sync).  
- Formal schema lands in Phase 2 against the field checklist.  
- Separate design doc + plan when starting Phase 2; do not silently expand Phase 1.

## ADR follow-up

**ADR-002** is **Accepted**: agents as non-install role packs + thin skill mirrors under `skills/orchestration/`; studio generates agents not a new install kind. Complements ADR-001; does not supersede it.

## Success criteria (Phase 1 done)

- [x] `agents/README.md` states boundaries and when to create an agent  
- [x] `_template` + `ship-review` demo present  
- [x] Thin `/ship-review` skill installs and points at the agent  
- [x] `docs/design/agent-workflow-fields.md` checklist exists  
- [x] Mirror consistency check in `check-layout` (or documented deferral with issue)  
- [x] ADR-002 Accepted  

## Open points

- **Resolved in plan:** copy-install uses synced `skills/orchestration/<name>/agent/` snapshot; CI enforces equality with `agents/<name>/`.
- `ship-review` on `build-loop` recommended menu — yes (plan Task 6).
