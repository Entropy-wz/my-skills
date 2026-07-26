#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string] $Path,
    [switch] $Force
)

$ErrorActionPreference = "Stop"
$target = (Resolve-Path -LiteralPath $Path).Path
if (-not (Test-Path (Join-Path $target ".git"))) {
    throw "Not a git repo: $target"
}

$here = Split-Path -Parent $PSScriptRoot
$hooksSrc = Join-Path $here "hooks"
$hooksDst = Join-Path $target ".githooks"

Push-Location $target
try {
    $existing = ""
    try { $existing = (git config --get core.hooksPath 2>$null) } catch { $existing = "" }
    if ($LASTEXITCODE -notin 0, 1) {
        # 1 = key not set; other = real failure
        throw "git config --get core.hooksPath failed (exit $LASTEXITCODE)"
    }
    if ($existing -and ($existing -ne ".githooks") -and ($existing -ne ".githooks/") -and -not $Force) {
        throw "core.hooksPath already set to '$existing'. Re-run with -Force to overwrite, or unset it first."
    }

    New-Item -ItemType Directory -Force -Path $hooksDst | Out-Null
    Copy-Item -Force (Join-Path $hooksSrc "pre-commit") (Join-Path $hooksDst "pre-commit")
    Copy-Item -Force (Join-Path $hooksSrc "pre-push") (Join-Path $hooksDst "pre-push")

    # Best-effort +x for WSL/Linux consumers of a Windows-installed tree
    foreach ($name in @("pre-commit", "pre-push")) {
        $hookFile = Join-Path $hooksDst $name
        if (Get-Command chmod -ErrorAction SilentlyContinue) {
            & chmod +x $hookFile 2>$null
        }
    }

    git config core.hooksPath .githooks
    if ($LASTEXITCODE -ne 0) {
        throw "git config core.hooksPath .githooks failed (exit $LASTEXITCODE) — hooks copied but NOT wired"
    }

    $verify = (git config --get core.hooksPath)
    if ($LASTEXITCODE -ne 0 -or -not $verify) {
        throw "hooksPath verify failed after install"
    }
}
finally {
    Pop-Location
}

Write-Host "Installed git hooks → $hooksDst (core.hooksPath=$verify)"
Write-Host "Note: outbound ship still uses ship-gate / run-gates."
Write-Host "Bypass force/delete guard: GIT_HOOKS_ALLOW_FORCE=1"
