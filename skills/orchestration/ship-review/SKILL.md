---
name: ship-review
description: Outbound merge-readiness review script — pin fixed-point, choose effort, emit ranked review skeleton or hand off to ship-gate for gates. Does not push or open PRs. Trigger phrases — "ship-review", "/ship-review", "出站审查", "merge review script", "出货前审查剧本".
disable-model-invocation: true
---

# Ship Review (thin entry)

**Thin skill.** All steps, bans, and handoffs live in the role pack — do not restate them here.

## Role pack (required — skill-local snapshot)

Resolve **from this skill directory** (works after install into `~/.cursor/skills/ship-review/`):

| File | Role |
| --- | --- |
| [`agent/AGENT.md`](agent/AGENT.md) | Authoritative steps / boundaries / handoffs |
| [`agent/prompt.md`](agent/prompt.md) | Optional model-facing role text |

1. **Read** `./agent/AGENT.md` (and `./agent/prompt.md` if present).
2. **Execute** that pack only.
3. **Stop** when the pack says stop.

Contributor SoT: `agents/ship-review/` in the my-skills checkout — edit there first, then sync
into `./agent/` (ADR-002).

If `./agent/AGENT.md` is missing after install: the **skill-local snapshot is broken**. Tell the
user to re-run install from the my-skills repo (`install.ps1` / `install.sh`, preferably
`-Copy` / `--copy` so `agent/` is copied). Do **not** invent steps. Do **not** treat
`MY_SKILLS_ROOT` as a fix — this skill only Reads `./agent/`, not a live `agents/` tree.
