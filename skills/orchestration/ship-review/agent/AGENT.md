# Agent: ship-review

## Purpose

Outbound **merge-readiness review script**: pin a fixed point, choose effort, produce a
ranked review skeleton (or hand off to `/ship-gate` when gates are required). Does **not**
replace `ship-gate` or `work-lanes`.

## When

- User wants a pre-merge / mentor-style review before claiming ship-ready.
- Triggers: `/ship-review`, "ship-review", "出站审查", "merge review script", "出货前审查剧本".

## When not

- Need gates + Verification paste first → `/ship-gate` (or ask, then hand off).
- Only teaching Standards‖Spec with no rerank → `code-review`.
- Deciding push / PR / issues → `work-lanes` Lane C (after evidence).
- Still designing → `clarify-and-plan` / Lane A.

## Steps

1. **Confirm fixed-point** — default `origin/main` (or the ref the user names). Run
   `git rev-parse <fixed-point>` and `git rev-parse HEAD`.
2. **Build review scope** (always combine commit range **and** dirty tree — never drop WIP):
   1. Compute three-dot: `git diff --stat <fixed-point>...HEAD` and
      `git log <fixed-point>..HEAD --oneline`.
   2. Always collect working tree:
      - tracked: `git diff <fixed-point>` (covers staged + unstaged vs the fixed-point tip)
      - names: `git status --short` (staged / unstaged / **untracked**)
      - **untracked bodies:** for every `??` path in status, **Read** the file (or
        directory’s relevant files). Status names alone are not enough.
   3. **If three-dot is non-empty:** scope = commits in that range **plus** the working-tree
      set from (2). Say so explicitly (“commits + dirty tree”).
   4. **If three-dot is empty:**
      - Do **not** stop.
      - If `HEAD` **equals** `<fixed-point>` (typical local WIP on main): scope = working
        tree vs fixed-point from (2) only. Tell the user this is WT scope, not merge-base…HEAD.
      - If `HEAD` is a **strict ancestor** of `<fixed-point>` (local behind remote): do **not**
        treat `git diff <fixed-point>` as the primary review. Warn that the branch is behind;
        ask to `git fetch` / fast-forward (or name an intentional base). Until caught up,
        review only the dirty working tree against `HEAD` (`git diff HEAD` + status + Read
        untracked) — not the full “delete remote commits” two-dot vs `<fixed-point>`.
      - Otherwise (empty three-dot for another reason): same as WT-vs-`HEAD` + status + Read
        untracked; state the limitation.
3. **Confirm effort** — default `medium` (`low` / `medium` / `high` / `ultra` per
   `merge-code-review`).
4. **Gates branch** — if the user also wants gates / "能不能推" / Verification from runners:
   **handoff to `/ship-gate`** and stop this pack (do not reimplement `run-gates`).
5. **Review** — follow `merge-code-review` on the scope from step 2 (including untracked file
   contents). Emit the report skeleton: Critical / Important / Spec gaps / Verification
   suggested.
6. **Stop** — remind: push / PR / issues only via `work-lanes` Lane C; prefer `/ship-gate`
   before any ship claim if gates were not run.

## Handoffs

| Situation | Go to |
| --- | --- |
| Gates / Verification from repo runners | `/ship-gate` |
| Lane / remote decisions | `/work-lanes` |
| Teaching two-axis review only | `/code-review` |
| Diff walkthrough | `/hunk-walkthrough` |

## Boundaries

- **Forbidden:** `git push`, `gh pr create` / `edit`, `gh issue create`, merging, Approve/Request-changes.
- **Forbidden:** re-encoding `tools/run-gates` inside this pack.
- Advisory review only — human owns merge call.

## Inputs

- Target repo root (cwd or explicit path).
- Fixed-point ref (default `origin/main`).
- Effort level (default medium).
- Optional: "include gates" → step 4 handoff.

## Outputs

- Merge-review markdown (or clear handoff note to `/ship-gate`).
- Explicit stop + Lane C reminder.
