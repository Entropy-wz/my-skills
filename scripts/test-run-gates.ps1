#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$runGates = Join-Path $repoRoot "tools\run-gates.ps1"
$failed = $false
$script:childExit = 0

function Fail([string]$Msg) {
    Write-Host "[FAIL] $Msg"
    $script:failed = $true
}
function Ok([string]$Msg) { Write-Host "[ok]   $Msg" }

# Run run-gates.ps1 in a child powershell and capture ALL streams to a temp log
# via *> so a native tool writing to stderr never trips our Stop preference.
# Sets $script:childExit; returns the combined log text.
function Invoke-RunGates([string[]]$RgArgs) {
    $log = Join-Path $env:TEMP ("rg-" + [guid]::NewGuid().ToString("n") + ".log")
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runGates @RgArgs *> $log
        $script:childExit = $LASTEXITCODE
        if (Test-Path -LiteralPath $log) {
            return (Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue)
        }
        return ""
    }
    finally {
        Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $runGates)) {
    Fail "missing tools/run-gates.ps1"
    Write-Host "test-run-gates: FAILED"
    exit 1
}

# A) DryRun on this repo must discover check-layout
$dry = Invoke-RunGates @("-Path", $repoRoot, "-DryRun")
if ($childExit -eq 4) {
    Fail "DryRun exit 4 (no gates) - expected check-layout discovery"
}
elseif ($dry -notmatch "check-layout") {
    Fail "DryRun output did not mention check-layout.ps1"
}
else {
    Ok "DryRun discovers check-layout"
}

# B) Empty dir with explicit -Path -> exit 4 (no upward walk when -Path is given)
$tmp = Join-Path $env:TEMP ("run-gates-empty-" + [guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $null = Invoke-RunGates @("-Path", $tmp, "-DryRun")
    if ($childExit -ne 4) {
        Fail "expected exit 4 for empty repo, got $childExit"
    }
    else { Ok "empty path exit 4" }
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# C) DryRun -Json must append a JSON line with summary DRY_RUN
$dryJson = Invoke-RunGates @("-Path", $repoRoot, "-DryRun", "-Json")
if ($dryJson -notmatch '"summary"\s*:\s*"DRY_RUN"') {
    Fail "DryRun -Json missing summary DRY_RUN JSON"
}
else { Ok "DryRun -Json emits DRY_RUN summary" }

# D) -Path pointing at a file -> exit 1 (not exit 4)
$filePath = Join-Path $repoRoot "README.md"
$null = Invoke-RunGates @("-Path", $filePath, "-DryRun")
if ($childExit -ne 1) {
    Fail "expected exit 1 for file -Path, got $childExit"
}
else { Ok "file -Path exits 1" }

if ($failed) { Write-Host "test-run-gates: FAILED"; exit 1 }
Write-Host "test-run-gates: PASSED"
exit 0

