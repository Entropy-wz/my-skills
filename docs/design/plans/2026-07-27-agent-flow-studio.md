# Plan: Agent Flow Studio (Phase 2)

> **For agentic workers:** `agents/ship-review/AGENT.md` is hand-authored — migrate must not
> overwrite it (D1). Prefer bite-sized tasks; verify with commands below.

**Goal:** Ship a local graph workbench that round-trips a fixture agent through
`workflow.yaml` → `AGENT.md` → snapshot sync, and can import `ship-review` as YAML-only.

**Architecture:** See [`docs/design/2026-07-27-agent-flow-studio.md`](../2026-07-27-agent-flow-studio.md)
and [ADR-003](../../adr/003-workflow-yaml-as-studio-sot.md).

**Tech stack:** React + Vite + React Flow; Node API on `127.0.0.1`; Ajv + YAML; vitest in kit.

---

## Task 1: Design + ADR (Lane A — may already be done)

**Files:**
- Create: `docs/design/2026-07-27-agent-flow-studio.md`
- Create: `docs/adr/003-workflow-yaml-as-studio-sot.md`
- Create: this plan
- Modify: ADR-002 Consequences, `agent-workflow-fields.md`, `agents/README.md`, `docs/README.md`
- Modify: `scripts/check-layout.ps1` (`node_modules|dist` exclude)

- [ ] **Step 1:** Confirm D1 + dual-SoT text present in design + ADR-003.
- [ ] **Step 2:** `check-layout` PASS after dangling-scan exclude.

```powershell
pwsh -File scripts/check-layout.ps1
```

---

## Task 2: Kit scaffold + schema

**Files:**
- Create: `kits/agent-flow-studio/README.md`, `.gitignore`, `.env.example`
- Create: `kits/agent-flow-studio/schema/workflow.schema.json`
- Create: `kits/agent-flow-studio/package.json` (workspaces or single package)
- **Do not** create `kits/agent-flow-studio/skill/SKILL.md`

- [ ] **Step 1:** Scaffold dirs `web/`, `server/`, `schema/`, `test/`.
- [ ] **Step 2:** Author JSON Schema (required fields, `step|skill|gate`, reject `agent|human` in v1 validation layer).
- [ ] **Step 3:** Gitignore `node_modules`, `dist`.

```powershell
Test-Path kits/agent-flow-studio/schema/workflow.schema.json
Test-Path kits/agent-flow-studio/skill/SKILL.md   # must be False
```

---

## Task 3: Server pipeline

**Files:** `kits/agent-flow-studio/server/**`

- [ ] **Step 1:** ROOT resolution + refuse start if not a my-skills root.
- [ ] **Step 2:** `GET` list/read; path guards; name regex.
- [ ] **Step 3:** Migrate: AGENT.md → `workflow.yaml` only.
- [ ] **Step 4:** Save: Ajv → YAML → generate AGENT.md → mirror/prune → thin SKILL scaffold.
- [ ] **Step 5:** Serve `web/dist` in run mode; bind `127.0.0.1` only.

---

## Task 4: Web graph UI

**Files:** `kits/agent-flow-studio/web/**`

- [ ] **Step 1:** Agent list + canvas (React Flow) + palette + props panel.
- [ ] **Step 2:** Save / Migrate actions + schema error display + dirty guard.
- [ ] **Step 3:** Dev proxy `/api` → server.

---

## Task 5: Thin skill + menu

**Files:**
- Create: orchestration thin skill leaf `agent-flow-studio` / `SKILL.md` (launch only; no `agent/`)
- Modify: build-loop `workflows/recommended.md` (orchestration menu)

- [ ] **Step 1:** Document `npm i && npm run dev` / ROOT env.
- [ ] **Step 2:** Menu entry under design/orchestration (not ship gate).

---

## Task 6: Tests + acceptance

**Files:** `kits/agent-flow-studio/test/**`

- [ ] **Step 1:** Schema valid/invalid fixtures.
- [ ] **Step 2:** Generator idempotence on fixture YAML.
- [ ] **Step 3:** Migrate node-count on sample AGENT.md.
- [ ] **Step 4:** Manual: fixture save → `check-layout` PASS; `ship-review` migrate leaves AGENT.md unchanged.

```powershell
cd kits/agent-flow-studio; npm test
pwsh -File ../../scripts/check-layout.ps1
# After migrate ship-review:
git -C ../.. diff -- agents/ship-review/AGENT.md   # empty
```

---

## Out of scope

Condition execution; `agent`/`human` UI; regenerating `ship-review/AGENT.md`; cloud;
FS Access API-only; forcing studio tests into smoke CI.

## Handoff

- Lane A: Tasks 1 (docs + check-layout exclude).
- Lane B: Tasks 2–6 locally; no push unless Lane C.
- Lane C: umbrella + children issues when shipping; Conventional Commits; no AI trailers.
