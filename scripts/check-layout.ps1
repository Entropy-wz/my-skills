<#
.SYNOPSIS
    Smoke-check toolkit layout + skill discovery (no install side effects).
#>
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$required = @(
    "skills",
    "kits",
    "kits\README.md",
    "kits\_template\skill\SKILL.md",
    "tools\README.md",
    "agents\README.md",
    "docs\README.md",
    "scripts\install.ps1",
    "scripts\install.sh",
    "README.md"
)

$failed = $false
foreach ($rel in $required) {
    $path = Join-Path $repoRoot $rel
    if (-not (Test-Path $path)) {
        Write-Host "[FAIL] missing: $rel"
        $failed = $true
    }
    else {
        Write-Host "[ok]   $rel"
    }
}

# Discover skills the same way install.ps1 intends
$skillsDir = Join-Path $repoRoot "skills"
$kitsDir = Join-Path $repoRoot "kits"
$skillNames = @()
$kitNames = @()

Get-ChildItem -Path $skillsDir -Directory |
    Where-Object { $_.Name -notlike "_*" -and (Test-Path (Join-Path $_.FullName "SKILL.md")) } |
    ForEach-Object { $skillNames += $_.Name }

if (Test-Path $kitsDir) {
    Get-ChildItem -Path $kitsDir -Directory |
        Where-Object {
            $_.Name -notlike "_*" -and
            (Test-Path (Join-Path $_.FullName "skill\SKILL.md"))
        } |
        ForEach-Object { $kitNames += $_.Name }
}

Write-Host ""
Write-Host ("discover skills/: {0}" -f ($skillNames -join ", "))
Write-Host ("discover kits/ : {0}" -f ($(if ($kitNames.Count) { $kitNames -join ", " } else { "(none yet)" })))

# searxng kit expected once landed
$searxSkill = Join-Path $repoRoot "kits\searxng-search\skill\SKILL.md"
if (Test-Path $searxSkill) {
    if ($kitNames -notcontains "searxng-search") {
        Write-Host "[FAIL] kits/searxng-search/skill present but not discovered"
        $failed = $true
    }
    else {
        Write-Host "[ok]   kit searxng-search discoverable"
    }
}

if ($skillNames.Count -lt 1) {
    Write-Host "[FAIL] expected ≥1 installable skill under skills/"
    $failed = $true
}

# _template must NOT be discovered as installable kit
if ($kitNames -contains "_template") {
    Write-Host "[FAIL] _template must not be installable"
    $failed = $true
}
else {
    Write-Host "[ok]   _template skipped"
}

# name collisions
$overlap = $skillNames | Where-Object { $kitNames -contains $_ }
if ($overlap) {
    Write-Host ("[FAIL] name collision skills↔kits: {0}" -f ($overlap -join ", "))
    $failed = $true
}

if ($failed) {
    Write-Host ""
    Write-Host "check-layout: FAILED"
    exit 1
}

Write-Host ""
Write-Host "check-layout: PASSED"
exit 0
