---
name: parallel-ci-triage
description: Fetch failing GitHub Actions (or CI) logs, split independent failures across subagents, fix in parallel, re-check. Suggest when ship-gate fails — never auto-start. Trigger phrases — "parallel-ci-triage", "CI 失败并行修", "triage Actions".
disable-model-invocation: true
---

# Parallel CI Triage

## When to use / when not

Use when CI/Actions is red and failures look **independent** (different jobs/packages).

Don't use for a single obvious local failure — fix locally first.
**Never auto-start** from `ship-gate`; only when the user accepts a prompt or asks.

## Flow

1. **Collect** failing jobs — `gh run list` / `gh run view <id> --log-failed` (or CI UI export).
2. **Cluster** by independent root (lint vs tests vs type vs deploy).
3. **Dispatch** one subagent (or isolated context) per cluster with: failing log excerpt,
   likely paths, success criteria ("job X green").
4. **Integrate** fixes on one branch; resolve conflicts consciously.
5. **Re-run** — `gh run rerun` or push if user is on Lane C; under Lane B only commit locally
   and report what to re-run.
6. If still red after bounded retries ≤3 per cluster → stop and ask.

## ship-gate hint

When ship-gate exits ≠ 0 because a CI-equivalent gate failed, you may **ask**:
"Enable `parallel-ci-triage`?" — do not start it silently.

## Guardrails

- No force-push; no remote unless Lane C confirmed.
- Don't merge speculative fixes from agents without reading the diff.
- Prefer `systematic-debugging` inside a cluster when root cause is unclear.
