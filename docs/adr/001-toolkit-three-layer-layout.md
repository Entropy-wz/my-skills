# ADR-001: Toolkit three-layer layout (nested skills, flat install)

## Status

Accepted

## Date

2026-07-26

## Context

The personal toolkit grew from a flat `skills/` dump into skills, kits, tools, and many docs. Without a locked layout:

- README “cloud” categories drift from disk folders
- Agents invent parallel concepts (`modules/`, `plugins/`)
- Workflow menus and templates risk dual sources of truth
- Install/CI only understood one-level `skills/*/SKILL.md`

We need a durable structure that stays navigable in-repo, install-compatible with Cursor’s flat `~/.cursor/skills/<name>/`, and cheap to gate.

## Options Considered

### Option A: Nested by purpose in-repo; flat install name = leaf

- Pros: Matches mental model (orchestration / design / …); install API unchanged; leaf uniqueness is a clear contract
- Cons: Paths in docs/skills become longer; discovery must recurse; historical docs may cite old flat paths

### Option B: Keep skills fully flat; categories only in README diagrams

- Pros: Shortest paths; simplest discovery
- Cons: Disk layout does not scale; README cloud is decoration only; easy to lose the taxonomy

### Option C: Nested install paths (`~/.cursor/skills/<category>/<leaf>/`)

- Pros: Mirrors repo
- Cons: Breaks Cursor’s conventional flat skill root; higher migration cost for every machine

## Decision

We choose **Option A** and lock the following architecture:

1. **Three layers only** — `skills/` = process; `kits/` = runnable multi-part capabilities; `tools/` = shared CLI. No `modules/` or `plugins/` unless a future ADR defines distinct *install* semantics.
2. **Repo nesting, flat install** — `skills/<category>/<leaf>/SKILL.md`; install name = **leaf** → `~/.cursor/skills/<leaf>/`. Category directories never carry a root `SKILL.md`.
3. **Assets follow the skill** — menus, templates, and skill-owned workflows stay skill-local (e.g. `skills/orchestration/build-loop/workflows/recommended.md`). `docs/workflows/recommended.md` remains a stub pointer; edit only the skill-local copy.
4. **Kit boundary** — orchestration lives in `skills/`; runtime assets in `kits/`. Asset-only kits (no `skill/SKILL.md`) are valid. **Forbidden:** same install name as both a skill leaf and a kit with `skill/SKILL.md` (no dual SKILL).
5. **Docs entry** — `docs/README.md` is the “start here” map (main chain → workflow menu → intake decisions → review framework). ADR files live under `docs/adr/` (not `docs/decisions/`).
6. **Layout contracts in CI** — `check-layout` enforces discovery, unique leaf names, no dangling `skills/…` paths in active docs, `scan-skills`, and README cloud categories ⊆ on-disk categories.

Canonical category set (initial): `orchestration`, `design`, `quality`, `review`, `docs`, `frontend`, `ci`.

## Consequences

- Installers (`scripts/install.ps1`, `install.sh`) and `scripts/lib/SkillSources.ps1` recurse under `skills/`.
- New skills are created as `skills/<category>/<leaf>/` (copy from `_template` into the right category).
- Design archives under `docs/design/` may still mention pre-migration flat paths; active surfaces (`README`, `docs/README`, `docs/workflows`, `docs/adr`, `skills/**`, `kits/**`, `tools/**`) must stay consistent or fail the gate.
- Follow-ups: keep stub warning on `docs/workflows/recommended.md`; kit README states the no-dual-SKILL rule explicitly.
- Links: intake decisions `docs/design/2026-07-26-toolkit-intake-decisions.md`; architecture mindmap `docs/design/2026-07-26-readme-architecture-mindmap.md`.
