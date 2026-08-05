---
name: agent-flow-studio
description: Launch the local Agent Flow Studio graph workbench for role packs (workflow.yaml). Does not push or open PRs. Trigger phrases — "agent-flow-studio", "/agent-flow-studio", "角色包画板", "agent studio", "workflow.yaml editor".
disable-model-invocation: true
---

# Agent Flow Studio (launch entry)

Thin orchestration entry for the **asset-only** kit `kits/agent-flow-studio/` (no kit `skill/SKILL.md` — ADR-001).

## Start the workbench

1. Resolve the my-skills checkout (`MY_SKILLS_ROOT` or ask the user).
2. From that checkout:

```powershell
cd kits/agent-flow-studio
# optional: copy .env.example → .env and set ROOT=
npm install
npm run studio
```

3. Open `http://127.0.0.1:5173` (dev) or `http://127.0.0.1:8787` after `npm run build && npm start`.

## Reminders

- Studio-managed packs use `agents/<name>/workflow.yaml` as SoT ([ADR-003](../../../docs/adr/003-workflow-yaml-as-studio-sot.md)).
- Migrating `ship-review` writes YAML only — **does not** overwrite hand-authored `AGENT.md` (D1).
- Save mirrors the whole pack into `skills/orchestration/<name>/agent/` and may scaffold a thin skill.
- Do not create `kits/agent-flow-studio/skill/SKILL.md`.

## When not

- Need outbound review script → `/ship-review`
- Need gates → `/ship-gate`
- Lane / remote decisions → `/work-lanes`
