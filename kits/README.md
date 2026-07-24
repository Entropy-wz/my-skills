# Kits

**Capability kits** — multi-part capabilities that need more than a single `SKILL.md`.

Use a kit when the capability includes any of: Docker/infra, CLI tools, small agents, shared scripts, or design notes that should travel together.

## Layout

```
kits/<kit-name>/
├── README.md          # what this kit is, how to run it
├── skill/             # optional Cursor skill (must contain SKILL.md)
│   └── SKILL.md
├── tools/             # optional scripts / CLIs used by the skill or agent
├── agents/            # optional small agent prompts / runners (kit-local)
└── docker/            # optional compose / container config
```

Names: lowercase, hyphenated (`searxng-search`). Directories starting with `_` are templates/examples and are **not** installed.

## vs top-level `skills/`

| Put it in… | When |
| --- | --- |
| `skills/` | Pure orchestration / process skill (e.g. `build-loop`, `work-lanes`) — one folder, mostly prose |
| `kits/` | Capability with runtime pieces (infra, tools, agents) bundled with an optional skill |

## Install

`scripts/install.ps1` / `scripts/install.sh` install:

1. every `skills/<name>/SKILL.md` (skip `_…`)
2. every `kits/<name>/skill/SKILL.md` (skip `_…`)

Kit skill install name = **kit directory name**. Do not reuse a name that already exists under `skills/`.
