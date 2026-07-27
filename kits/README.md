# Kits

**Capability kits** — multi-part capabilities that need more than a single `SKILL.md`.

Use a kit when the capability includes any of: Docker/infra, CLI tools, small agents, shared scripts, or design notes that should travel together.

## Boundary (ADR-001)

| Layer | Owns | Example |
| --- | --- | --- |
| `skills/` | **Orchestration / process** (thin entry, menus, when-to-use) | `skills/frontend/frontend-craft` |
| `kits/` | **Runnable assets** (scripts, docker, hooks, scaffolds) | `kits/frontend-craft` |
| `tools/` | Shared CLI across kits | `tools/run-gates` |

Rules:

1. Orchestration stays in `skills/`; assets stay in `kits/`.
2. **Asset-only kits** (no `skill/SKILL.md`) are correct when a skill already owns the entry — e.g. `frontend-craft`, `git-hooks` (hooks install via `tools/install.*`).
3. **Forbidden: dual SKILL under the same install name** — do not ship both `skills/**/<name>/SKILL.md` and `kits/<name>/skill/SKILL.md`. Pick one install surface.
4. Do not invent `modules/` / `plugins/` here; kits are the multi-part packing unit.

## Layout

```
kits/<kit-name>/
├── README.md          # what this kit is, how to run it
├── skill/             # optional Cursor skill (must contain SKILL.md)
│   └── SKILL.md
├── tools/             # optional scripts / CLIs
├── agents/            # optional kit-local agents
└── docker/            # optional compose / containers
```

Names: lowercase, hyphenated (`searxng-search`). Directories starting with `_` are templates/examples and are **not** installed.

## vs top-level `skills/`

| Put it in… | When |
| --- | --- |
| `skills/<category>/<leaf>/` | Pure orchestration / process (prose + skill-local assets) |
| `kits/<name>/` | Runtime pieces bundled; optional `skill/` only if there is **no** same-named skill leaf |

## Install

`scripts/install.ps1` / `scripts/install.sh` install:

1. every `skills/**/<leaf>/SKILL.md` (skip `_…`; install name = **leaf**)
2. every `kits/<name>/skill/SKILL.md` (skip `_…`; install name = kit directory name)

Kit skill install name must not collide with any skill leaf.
