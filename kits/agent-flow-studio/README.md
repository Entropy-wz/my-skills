# Agent Flow Studio

Local **graph workbench** for my-skills role packs (`agents/<name>/`).  
Design: [`docs/design/2026-07-27-agent-flow-studio.md`](../../docs/design/2026-07-27-agent-flow-studio.md) · ADR-003.

**Asset-only kit** — no `skill/SKILL.md` here (ADR-001). Cursor entry: orchestration skill `agent-flow-studio`.

## Requirements

- Node 20+
- A my-skills checkout as `ROOT` (must contain `agents/` and `skills/orchestration/`)

## Run (dev)

```powershell
cd kits/agent-flow-studio
copy .env.example .env   # set ROOT=C:\path\to\my-skills  (or set MY_SKILLS_ROOT)
npm install
npm run studio           # API :8787 + Vite :5173 (proxies /api)
```

Open http://127.0.0.1:5173

## Run (static)

```powershell
npm run build
npm start                # serves web/dist + API on 127.0.0.1:8787
```

## D1 note

Migrating `ship-review` writes `workflow.yaml` only — it does **not** overwrite the hand-authored `AGENT.md`.

## Tests

```powershell
npm test
```
