# Agents Layer + `ship-review` — Implementation Plan

> **For agentic implementers:** Work task-by-task, top to bottom. Check off each step only after its **Verification** passes. This plan is **local-only** — never run `git push`, `gh issue`, `gh pr`, or any remote command unless the owner explicitly moves you to **Lane C** (see Handoff). All edits are file writes plus running `check-layout.ps1`.

## Goal

Land **Phase 1** of the agents layer in the `my-skills` repo:

1. Introduce `agents/` as an editorial layer of **non-install role packs**.
2. Ship a reusable `agents/_template/`.
3. Deliver the `ship-review` demo: an editorial role pack **plus** a thin skill mirror under `skills/orchestration/ship-review/` that carries a synced `agent/` snapshot for copy-install.
4. Document the workflow-fields **checklist** (no formal schema this phase).
5. Enforce the agent↔skill mirror with a CI equality check in `check-layout.ps1`.
6. **ADR-002** is already **Accepted** (done before implementation).

This is a documentation + one-script-change effort. There is **no new install kind**, no UI, and no schema format.

## Architecture

Read this before touching files:

- **`agents/<name>/` is the single source of truth (SoT).** All editorial changes to a role pack happen here first (`AGENT.md`, optional `prompt.md`).
- **`skills/orchestration/<name>/` is a thin Cursor entry point.** Its `SKILL.md` only carries frontmatter + triggers + a pointer; it does **not** duplicate the long role-pack body.
- **`skills/orchestration/<name>/agent/` is a synced snapshot** of `agents/<name>/`. It exists so `copy-install` (which physically copies the skill directory) still ships the full role pack. Symlink installs resolve the same relative `./agent/` path.
- **Installers never treat `agents/` as an install kind.** Discovery (`Get-SkillSources`) only scans skills/kits; `agents/` is invisible to it. There is no fourth install kind and no `modules/` or `plugins/`.

**The sync rule (must be unmistakable):** `agents/<name>/` → copied into → `skills/orchestration/<name>/agent/`. The two must be **byte-for-byte identical** in file set and content. `check-layout.ps1` FAILS the build if they diverge. Never edit the `agent/` snapshot directly; edit the SoT and re-copy.

**Tech stack:** Markdown skills/agents; PowerShell 5.1 (`scripts/check-layout.ps1`); existing install scripts are **unchanged** — their discovery rules already ignore `agents/`.

**References:**
- Design (approved): `docs/design/2026-07-27-agents-layer-and-ship-review.md`
- ADR: `docs/adr/002-agents-as-role-packs.md` (**Accepted**)

## Global Constraints

- **No fourth install kind.** No `modules/`, no `plugins/`. `agents/` is editorial only.
- **`ship-review` does not reimplement gates.** When gates are requested, it hands off to `/ship-gate` — it never re-runs `run-gates` logic itself.
- **No remote side effects.** `ship-review` and every agent pack forbid `push`, PR creation, and issue creation.
- **Edit SoT first, then sync.** Change `agents/<name>/`, then copy into `skills/orchestration/<name>/agent/`. Never edit the snapshot alone.
- **Commits:** Conventional Commits. **No AI `Co-authored-by`** trailer in commit metadata.
- **Branch (only when shipping on Lane C):** `Entropy-wz/<issue#>-feat-agents-ship-review`. Issue numbers exist only on Lane C.

## File Map

| Path | Responsibility |
| --- | --- |
| `docs/adr/002-agents-as-role-packs.md` | Decision record (**Accepted**) |
| `agents/README.md` | Layer boundaries, when to create an agent, the sync rule |
| `agents/_template/AGENT.md` | Role-pack template sections |
| `agents/_template/prompt.md` | Optional prompt stub |
| `agents/ship-review/AGENT.md` | Demo role pack (SoT) |
| `agents/ship-review/prompt.md` | Demo prompt (SoT) |
| `skills/orchestration/ship-review/SKILL.md` | Thin trigger skill |
| `skills/orchestration/ship-review/agent/AGENT.md` | Synced snapshot of SoT |
| `skills/orchestration/ship-review/agent/prompt.md` | Synced snapshot of SoT |
| `docs/design/agent-workflow-fields.md` | Workflow field **checklist** (no schema) |
| `scripts/check-layout.ps1` | Mirror-equality contract (CI check) |
| `skills/orchestration/build-loop/workflows/recommended.md` | Menu entry for `/ship-review` (optional task) |
| `README.md` / `docs/README.md` | One-line pointers to the agents layer |

---

### Task 1 — ADR-002 status + `agents/README.md`

**Files:**
- Modify: `docs/adr/002-agents-as-role-packs.md` (Status already **Accepted**)
- Create/overwrite: `agents/README.md`

- [x] **Step 1:** ADR-002 Status = `Accepted` (owner 2026-07-27). Ensure Consequences links design + this plan.
- [ ] **Step 2:** Write `agents/README.md` covering: (a) agent vs skill vs kit distinction; (b) SoT + `agent/` snapshot sync rule; (c) `agents/` is not discovered by installers; (d) pointers to `_template` and `ship-review`; (e) links to ADR-002 and the design doc.
- [ ] **Step 3:** Confirm no `SKILL.md` exists anywhere under `agents/`, so installer discovery cannot pick it up.

**Verification:**
```powershell
# ADR still Proposed, links present:
Select-String -Path docs/adr/002-agents-as-role-packs.md -Pattern 'Status.*Accepted','2026-07-27-agents-layer-and-ship-review'
# README exists and mentions the sync rule + no-install:
Select-String -Path agents/README.md -Pattern 'sync','install'
# No skill manifests leaked into agents/:
Get-ChildItem -Recurse agents -Filter SKILL.md   # expect: no output
```

---

### Task 2 — `_template` pack

**Files:**
- Create: `agents/_template/AGENT.md`
- Create: `agents/_template/prompt.md`

- [ ] **Step 1:** Write `agents/_template/AGENT.md` with these sections: Purpose, When, When not, Steps, Handoffs, Boundaries, Inputs, Outputs.
- [ ] **Step 2:** Write `agents/_template/prompt.md` as a one-paragraph stub ending with a clear `replace me` marker.
- [ ] **Step 3:** Confirm the `_`-prefix convention is documented so any future mirror scan skips `_template` (the `check-layout` enumeration in Task 5 must exclude `_*`).

**Verification:**
```powershell
Test-Path agents/_template/AGENT.md, agents/_template/prompt.md   # both True
Select-String -Path agents/_template/AGENT.md -Pattern 'Purpose','When not','Handoffs','Boundaries'
```

---

### Task 3 — `ship-review` agent + thin skill + synced snapshot

**Files:**
- Create: `agents/ship-review/AGENT.md` (SoT)
- Create: `agents/ship-review/prompt.md` (SoT)
- Create: `skills/orchestration/ship-review/SKILL.md`
- Create: `skills/orchestration/ship-review/agent/AGENT.md` (snapshot)
- Create: `skills/orchestration/ship-review/agent/prompt.md` (snapshot)

- [ ] **Step 1:** Write `agents/ship-review/AGENT.md` following the design steps: establish a fixed point, choose review effort, hand off to `/ship-gate` when gates are requested, run a `merge-code-review` skeleton, and stop for work-lanes handoff. Explicitly forbid push / PR / issue creation in Boundaries.
- [ ] **Step 2:** Write a concise `agents/ship-review/prompt.md` for the reviewer role.
- [ ] **Step 3:** Copy both SoT files verbatim into `skills/orchestration/ship-review/agent/` (this is the snapshot; do not hand-edit it).
- [ ] **Step 4:** Write the thin `skills/orchestration/ship-review/SKILL.md`: frontmatter `name: ship-review` + triggers; body instructs the agent to Read `./agent/AGENT.md` (relative to the installed skill dir) and follow it. Do not duplicate the long steps; optionally mention the repo `agents/ship-review/` path for contributors.
- [ ] **Step 5:** Do a manual copy-install smoke test and confirm the snapshot ships.

**Verification:**
```powershell
# Snapshot is byte-identical to SoT:
(Get-FileHash agents/ship-review/AGENT.md).Hash -eq (Get-FileHash skills/orchestration/ship-review/agent/AGENT.md).Hash   # True
(Get-FileHash agents/ship-review/prompt.md).Hash -eq (Get-FileHash skills/orchestration/ship-review/agent/prompt.md).Hash   # True
# Skill is thin (points to ./agent/AGENT.md, no push/PR):
Select-String -Path skills/orchestration/ship-review/SKILL.md -Pattern './agent/AGENT.md'
# Copy-install ships the snapshot:
powershell -File scripts/install.ps1 -Copy
Test-Path "$HOME/.cursor/skills/ship-review/agent/AGENT.md"   # True
```

---

### Task 4 — Workflow field checklist + docs entry

**Files:**
- Create: `docs/design/agent-workflow-fields.md`
- Modify: `docs/README.md` (add link)
- Modify: `README.md` (agents/ line notes role packs + ADR-002)

- [ ] **Step 1:** Write `docs/design/agent-workflow-fields.md` as a **checklist** of the fields from the design (`id`, `name`, `nodes[]`, `edges[]`, `defaults`, `banned_actions`). State clearly: **format is TBD in Phase 2 — this is a checklist, not a schema.**
- [ ] **Step 2:** Link `agent-workflow-fields.md` from both `docs/README.md` and `agents/README.md`.
- [ ] **Step 3:** Add/adjust the `agents/` one-liner in the root `README.md` tree so it names role packs and references ADR-002.

**Verification:**
```powershell
Select-String -Path docs/design/agent-workflow-fields.md -Pattern 'banned_actions','Phase 2','checklist'
Select-String -Path docs/README.md,agents/README.md -Pattern 'agent-workflow-fields|workflow-fields'
Select-String -Path README.md -Pattern 'agents/','ADR-002'
```

---

### Task 5 — `check-layout` mirror contract

**Files:**
- Modify: `scripts/check-layout.ps1`

- [ ] **Step 1:** After existing skill discovery, enumerate `agents/<name>/AGENT.md`, skipping any name starting with `_` (e.g. `_template`).
- [ ] **Step 2:** For each enumerated `<name>`, require `skills/orchestration/<name>/SKILL.md` and `skills/orchestration/<name>/agent/AGENT.md` to exist; FAIL if either is missing.
- [ ] **Step 3:** Compare every file present in `agents/<name>/` against its counterpart in `skills/orchestration/<name>/agent/` using `Get-FileHash` (or byte compare); FAIL on any missing counterpart or content mismatch.
- [ ] **Step 4:** Run the script and confirm PASS.

**Verification:**
```powershell
powershell -File scripts/check-layout.ps1   # exit 0 / PASS
# Negative check: temporarily edit the snapshot and confirm the script FAILS, then revert.
```

---

### Task 6 — Recommended menu + ADR accept

**Files:**
- Modify: `skills/orchestration/build-loop/workflows/recommended.md`
- Modify: `docs/adr/002-agents-as-role-packs.md` (Status)

- [ ] **Step 1:** Add an outbound/review menu line for `/ship-review`, noting its relationship to `/ship-gate` (review vs. gate execution).
- [ ] **Step 2:** Make the menu change only in the skill-local `recommended.md`; any docs copy stays a pointer stub.
- [x] **Step 3:** ADR-002 set to `Accepted` (owner 2026-07-27).
- [ ] **Step 4:** Run a final `check-layout` PASS; then stop and await owner direction for the Lane B → Lane C handoff.

**Verification:**
```powershell
Select-String -Path skills/orchestration/build-loop/workflows/recommended.md -Pattern 'ship-review','ship-gate'
Select-String -Path docs/adr/002-agents-as-role-packs.md -Pattern 'Status.*Accepted'
powershell -File scripts/check-layout.ps1   # PASS
```

---

## Phase 2 (out of scope for this plan)

- Design doc for `kits/agent-flow-studio` + a **formal** workflow schema.
- No UI work belongs under any Phase 1 task.

## Handoff

- **Lane B:** implement Tasks 1–6 locally; no remote commands.
- **Lane C:** only when the owner asks to commit / push / PR. Branch: `Entropy-wz/<issue#>-feat-agents-ship-review`. Conventional Commits, no AI `Co-authored-by`.
- **ADR-002:** **Accepted** (2026-07-27).

## Definition of Done

- [ ] `agents/README.md`, `agents/_template/`, and `agents/ship-review/` exist and follow the SoT convention.
- [ ] `skills/orchestration/ship-review/` is a thin skill whose body resolves `./agent/AGENT.md`, carrying an `agent/` snapshot byte-identical to `agents/ship-review/`.
- [ ] `ship-review` forbids push / PR / issue creation and hands gate execution to `/ship-gate`.
- [ ] `docs/design/agent-workflow-fields.md` documents the field **checklist** (format explicitly deferred to Phase 2) and is linked from `docs/README.md` and `agents/README.md`.
- [ ] `scripts/check-layout.ps1` enforces agent↔snapshot equality (skipping `_*`) and PASSES; it FAILS on a deliberate mismatch.
- [ ] `README.md` names the `agents/` role-pack layer and references ADR-002.
- [ ] No new install kind was added; installer discovery still ignores `agents/`.
- [x] ADR-002 is `Accepted`.
- [ ] No remote side effects occurred unless the owner moved work to Lane C.
