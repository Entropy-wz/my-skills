---
name: ship-gate
description: Pre-ship gate runner and review handoff. Discover/run repo gates via tools/run-gates, emit Verification markdown, then merge-code-review (optional hunk). Stops before push/PR — hand off to work-lanes Lane C. Trigger phrases — "ship-gate", "/ship-gate", "pre-ship", "出货前检查", "ready to ship gates", "能推了吗先跑门".
disable-model-invocation: true
---

# Ship Gate

Pre-ship orchestrator: discover and run the repo's gates, paste Verification evidence,
then hand off to merge-readiness review. **Stops before any remote action** — push, PR,
and issue creation belong to `work-lanes` Lane C.

Fixed sequence — never skip a phase, never silently escalate:

```
confirm repo -> run gates -> paste Verification -> review -> (optional hunk) -> stop
```

## When to use

- About to enter `work-lanes` Lane C (push / PR / ship claim).
- Need paste-ready **Verification** markdown plus a default merge-readiness review.
- User says `/ship-gate`, "pre-ship", "出货前检查", "ready to ship gates", or "能推了吗先跑门".

## When not

- Still designing or scoping → `work-lanes` Lane A.
- Mid-implementation test/fix loop → follow `docs/workflows/recommended.md` (bounded retries ≤3); not ship-gate.
- User asked only for review without gates → `merge-code-review` alone.
- User wants to push / open PR now → `work-lanes` Lane C (after ship-gate if gates not yet run).

## Resolve `run-gates` runner

Find the gate runner in this order — do not guess silently:

1. `<target-repo>/tools/run-gates.ps1` if present (vendored or copied).
2. `$env:MY_SKILLS_ROOT/tools/run-gates.ps1` (or `MY_SKILLS_ROOT/tools/run-gates.sh`) if set.
3. Ask the user for their my-skills checkout path; stop if neither exists.

**Always call the runner from the resolved absolute directory** (sibling of the file you found).

| Platform | Command |
| --- | --- |
| Windows / when PowerShell exists | `powershell -NoProfile -ExecutionPolicy Bypass -File <resolved>/run-gates.ps1 -Path <repo>` |
| Unix, no PowerShell | `<resolved>/run-gates.sh -Path <repo>` where `<resolved>` is the same `tools/` dir as the `.ps1` you found (usually `$MY_SKILLS_ROOT/tools`) |

Do **not** invent a relative `tools/run-gates.sh` under the target repo unless that file actually exists there.

## Flow

### 1. Confirm repo root

Identify the target repository. If the user is in a subfolder, resolve to the repo root
(same semantics as `run-gates -Path`: explicit path = that directory; omitted = walk up to
`.git`).

### 2. Run gates

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <run-gates.ps1> -Path <repo>
```

Optional flags: `-DryRun` (plan only), `-Json` (machine summary after markdown).

Capture stdout — it is the **Verification** block (env, repo, timestamp, each command
→ PASS/FAIL + duration, summary line, log tails on failure).

### 3. Paste Verification; stop on red

Paste the full gate output into the session.

| Exit code | Meaning | Action |
| --- | --- | --- |
| 0 | All gates passed | Continue to review |
| 1 | At least one gate failed | **STOP** — report failures; do not claim ready |
| 2 | Missing runtime (npm, make, etc.) | **STOP** — tell user what to install |
| 4 | No gates discovered | **STOP** — repo has no discoverable gates |

If exit ≠ 0, stop unless the user explicitly asks to proceed to review anyway (record the
override in the session).

### 4. Merge-readiness review

When gates are green (or user overrode), invoke **`merge-code-review`** against `main`
(default effort: medium). Override base branch or effort if the user specifies.

Do not hand-roll a review — use the skill's find→verify→cap pipeline.

### 5. Optional hunk walkthrough

If the user said **+hunk** (or asked for a diff walkthrough), invoke **`hunk-walkthrough`**
after the review findings.

### 6. Summarize ready / not ready

End with a clear verdict:

- **Ready for Lane C** — gates green, review findings surfaced (user decides fixes).
- **Not ready** — gate failures, missing runtime, or blocking review findings the user
  must address first.

### 7. STOP — hand off to work-lanes

Never `git push`, `gh pr create`, or `gh issue create` from ship-gate. If the user wants
to ship, switch to **`work-lanes` Lane C** and attach this session's Verification block.

## Boundaries vs other skills

| Skill | Role |
| --- | --- |
| `work-lanes` | Lanes + remote; Lane C gate checklist prefers `/ship-gate` first |
| `build-loop` | Thin workflow menu (`docs/workflows/recommended.md`); ship-gate is the pre-ship re-gate |
| `merge-code-review` | Invoked by ship-gate; semantics unchanged |
| `hunk-walkthrough` | Optional diff walkthrough when user says +hunk |
| `commit-message` | Not invoked here; use in Lane C when committing |

Failures: do not auto-fix gate or review findings. Re-run `/ship-gate` after fixes.
If failures look like independent CI/job clusters, you may **ask** whether to run
`parallel-ci-triage` — never start it automatically.

## Progress checklist

Copy and track:

```
- [ ] Repo root confirmed
- [ ] run-gates.ps1 resolved (target repo, MY_SKILLS_ROOT, or user path)
- [ ] Gates run; Verification pasted
- [ ] Exit code checked (stopped on red unless user overrode)
- [ ] merge-code-review invoked (default vs main, medium)
- [ ] (+hunk) hunk-walkthrough if requested
- [ ] Ready / not ready summary
- [ ] Stopped — no push / PR / issue; hand off to work-lanes Lane C if shipping
```

## Guardrails

- No auto-fix of gate or review findings.
- No "done" or "shipped" claim without green gates (or explicit user override recorded).
- Never push, open PRs, or create issues — that belongs to `work-lanes`.
- Do not reimplement review; hand off to `merge-code-review` / `hunk-walkthrough`.
- Do not auto-start Docker, SearXNG, or other infra unless a repo's own `scripts/gates.*` does.

## Example invocations

- "/ship-gate — about to open a PR for this branch."
- "Run pre-ship gates and review against main."
- "出货前检查，跑门然后 review。"
- "/ship-gate +hunk on the auth refactor."
- "Ready to ship gates — is this mergeable?"

## Example Verification output (my-skills)

```
## Gate results
- env: Windows_NT | repo: C:\Users\lenovo\my-skills | when: 2026-07-25T13:02:25Z
- ran:
  - `powershell -File scripts/check-layout.ps1` -> PASS (7s)
- summary: PASS (1 ran)
```

Paste this block into the PR/issue Verification section when entering Lane C.
