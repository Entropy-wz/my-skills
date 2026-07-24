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
    "scripts\lib\SkillSources.ps1",
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

# Same discovery as install.ps1 (shared lib)
$skillsDir = Join-Path $repoRoot "skills"
$kitsDir = Join-Path $repoRoot "kits"
. (Join-Path $PSScriptRoot "lib\SkillSources.ps1")
$sources = @(Get-SkillSources -SkillsDir $skillsDir -KitsDir $kitsDir)
$skillNames = @($sources | Where-Object Kind -eq "skill" | ForEach-Object { $_.Name })
$kitNames = @($sources | Where-Object Kind -eq "kit" | ForEach-Object { $_.Name })

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

# Optional install regression (review findings) when present
$smoke = Join-Path $PSScriptRoot "smoke-install.ps1"
if (Test-Path $smoke) {
    Write-Host ""
    Write-Host "---- smoke-install ----"
    & powershell -ExecutionPolicy Bypass -File $smoke
    if ($LASTEXITCODE -ne 0) {
        $failed = $true
    }
}

if ($failed) {
    Write-Host ""
    Write-Host "check-layout: FAILED"
    exit 1
}

Write-Host ""
Write-Host "check-layout: PASSED"
exit 0
