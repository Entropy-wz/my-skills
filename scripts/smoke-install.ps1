<#
.SYNOPSIS
    Regression smoke for install.sh / install.ps1 (review findings).
#>
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$failed = $false

function Fail([string]$Msg) {
    Write-Host "[FAIL] $Msg"
    $script:failed = $true
}

function Ok([string]$Msg) {
    Write-Host "[ok]   $Msg"
}

Set-Location $repoRoot

# 1) install.sh must stay Bash 3.2-safe (no mapfile / declare -A in code)
$sh = Get-Content "scripts\install.sh" -Raw
if ($sh -match '(?m)^\s*mapfile\b' -or $sh -match '(?m)^\s*declare\s+-A\b') {
    Fail "install.sh still uses mapfile or declare -A"
}
else {
    Ok "install.sh has no mapfile / declare -A"
}

if ($sh -notmatch '(?m)^\s*return 0\s*$') {
    Fail "install.sh collect_sources should end with return 0 (set -e safety)"
}
else {
    Ok "install.sh has return 0 for set -e safety"
}

# 2) Optional kit without SKILL.md must not abort bash install
$bash = $null
foreach ($c in @("C:\Program Files\Git\bin\bash.exe", "bash")) {
    if (Get-Command $c -ErrorAction SilentlyContinue) {
        $bash = (Get-Command $c).Source
        break
    }
}

# Must NOT start with "_" — installers skip _* dirs, which would hide the set -e bug.
$fakeKit = Join-Path $repoRoot "kits\smoke-optional-kit"
New-Item -ItemType Directory -Force -Path (Join-Path $fakeKit "docker") | Out-Null
Set-Content -Path (Join-Path $fakeKit "docker\noop.txt") -Value "smoke"

try {
    if ($bash) {
        & $bash -n "scripts/install.sh"
        if ($LASTEXITCODE -ne 0) { Fail "bash -n install.sh failed" } else { Ok "bash -n install.sh" }

        & $bash "scripts/install.sh" --copy
        if ($LASTEXITCODE -ne 0) {
            Fail "install.sh --copy aborted with optional kit present (exit $LASTEXITCODE)"
        }
        else {
            Ok "install.sh --copy survives optional kit without SKILL.md"
        }
    }
    else {
        Write-Host "[skip] bash not available — install.sh runtime smoke skipped"
    }

    # 3) Kit install must expose tools/ next to SKILL.md
    $destSkill = Join-Path $HOME ".cursor\skills\searxng-search\SKILL.md"
    $destTools = Join-Path $HOME ".cursor\skills\searxng-search\tools\search.ps1"
    if (-not (Test-Path $destSkill)) { Fail "searxng-search SKILL.md missing after install" }
    else { Ok "searxng-search SKILL.md installed" }
    if (-not (Test-Path $destTools)) { Fail "searxng-search tools/ missing after kit install (copy path)" }
    else { Ok "searxng-search tools/ present after kit install" }

    # 4) Repo must not be wiped by reinstall
    if (-not (Test-Path (Join-Path $repoRoot "skills\build-loop\SKILL.md"))) {
        Fail "repo skills/build-loop wiped after install"
    }
    else {
        Ok "repo skills/ intact after install"
    }

    # 5) PS install twice (safe dest removal)
    powershell -ExecutionPolicy Bypass -File "scripts\install.ps1" -Copy | Out-Null
    powershell -ExecutionPolicy Bypass -File "scripts\install.ps1" -Copy | Out-Null
    if (-not (Test-Path (Join-Path $repoRoot "kits\searxng-search\tools\search.ps1"))) {
        Fail "repo kit tools wiped after double install.ps1 -Copy"
    }
    else {
        Ok "double install.ps1 -Copy left repo kit tools intact"
    }
}
finally {
    if (Test-Path $fakeKit) {
        Remove-Item -Recurse -Force $fakeKit
    }
}

if ($failed) {
    Write-Host ""
    Write-Host "smoke-install: FAILED"
    exit 1
}

Write-Host ""
Write-Host "smoke-install: PASSED"
exit 0
