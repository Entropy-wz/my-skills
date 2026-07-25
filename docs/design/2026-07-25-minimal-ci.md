# Design: Minimal CI for my-skills

Date: 2026-07-25  
Lane: A (design-only)  
Repo: [Entropy-wz/my-skills](https://github.com/Entropy-wz/my-skills)

## Goal

On every PR / push to `main`, run the same smoke we trust locally:

1. `scripts/check-layout.ps1` (includes discovery checks; may call smoke)
2. `scripts/smoke-install.ps1` (install.sh set -e / kit tools / wipe guards)

Fail the job if either exits non-zero. No deploy, no Docker, no SearXNG in CI for v1.

## Why this shape

- Scripts are **PowerShell-first**; GitHub `windows-latest` matches maintainer OS.
- `smoke-install` already skips bash runtime pieces when bash is absent, but **windows-latest + Git for Windows** usually provides bash — good enough to exercise `install.sh`.
- SearXNG Docker is environment-heavy and flaky in CI; keep it **local-only** until a later job.

## Proposed workflow

Path: `.github/workflows/smoke.yml`

```yaml
name: smoke

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  layout-and-install:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check layout (+ nested smoke if configured)
        shell: pwsh
        run: ./scripts/check-layout.ps1

      # If check-layout already invokes smoke-install, this second step is optional.
      # Prefer ONE invocation to save minutes — see Decision below.
      - name: Smoke install (explicit)
        if: false  # toggle per Decision
        shell: pwsh
        run: ./scripts/smoke-install.ps1
```

### Decision (recommend)

**Single step:** only run `./scripts/check-layout.ps1`, because current `check-layout.ps1` already nests `smoke-install.ps1`.  

Document in workflow comment: “check-layout includes smoke-install”.  

If we later split them (layout fast / smoke slow), enable two steps and add `paths` filters.

## Implementation tweaks (for Lane B, not this design commit scope)

Optional small hardening before CI lands (call out in the CI issue AC):

1. **Idempotent temp kit cleanup** — already in `finally`; ensure CI working tree stays clean (`git status --porcelain` empty after smoke) or add `git clean` of `kits/smoke-optional-kit` only.
2. **HOME isolation** — smoke writes to `~/.cursor/skills`. On the runner that is fine; do not assume a pre-existing skills tree. Consider `env: HOME: ${{ runner.temp }}/home` so CI does not touch the default profile oddly — **nice-to-have**.
3. **Do not require Docker** in smoke (today it does not start SearXNG) — keep it that way.
4. **Badge** in README (optional one-liner).

## Acceptance Criteria (for future issue)

- [ ] `.github/workflows/smoke.yml` exists and runs on PR + push to `main`
- [ ] Job uses `windows-latest` + `pwsh`
- [ ] `check-layout.ps1` is executed (and thereby smoke, unless split later)
- [ ] Red on intentional break (e.g. delete `scripts/lib/SkillSources.ps1` in a draft PR) — manual once
- [ ] No secrets / no Docker service containers in this workflow
- [ ] README links to the workflow or states “CI: layout + install smoke”

## Non-goals (v1)

- macOS/Linux matrix (can add `macos-latest` later for real Bash 3.2 if desired)
- Publishing actions / release automation
- SearXNG container e2e
- Caching npm/docker layers

## Suggested tracker (draft only — Lane A)

**Title:** `ci: run check-layout and smoke-install on windows-latest`  

**Body headers:** Why / What to build / Acceptance Criteria / Verification (paste first green run URL)  

**Parent:** optional new umbrella `chore(toolkit): quality gates` — or stand-alone chore issue (CI is small enough to be stand-alone).

## Effort

**S** — half day including one red/green validation PR.
