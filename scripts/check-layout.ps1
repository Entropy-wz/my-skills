<#
.SYNOPSIS
    Smoke-check toolkit layout + skill discovery + layout contracts (no install side effects).
.NOTES
    See ADR-001: nested skills by category; install name = leaf; three layers only.
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
    "docs\adr",
    "scripts\install.ps1",
    "scripts\install.sh",
    "scripts\lib\SkillSources.ps1",
    "scripts\scan-skills.ps1",
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

# Same discovery as install.ps1 (shared lib) — throws on bad depth / duplicate leaves
$skillsDir = Join-Path $repoRoot "skills"
$kitsDir = Join-Path $repoRoot "kits"
. (Join-Path $PSScriptRoot "lib\SkillSources.ps1")
$discoveryOk = $true
try {
    $sources = @(Get-SkillSources -SkillsDir $skillsDir -KitsDir $kitsDir)
}
catch {
    Write-Host "[FAIL] discovery: $_"
    $failed = $true
    $discoveryOk = $false
    $sources = @()
}

$skillSources = @($sources | Where-Object Kind -eq "skill")
$kitSources = @($sources | Where-Object Kind -eq "kit")
$skillNames = @($skillSources | ForEach-Object { $_.Name })
$kitNames = @($kitSources | ForEach-Object { $_.Name })

Write-Host ""
Write-Host ("discover skills/: {0}" -f ($skillNames -join ", "))
Write-Host ("discover kits/ : {0}" -f ($(if ($kitNames.Count) { $kitNames -join ", " } else { "(none yet)" })))

# Contract: every skill is skills/<category>/<leaf>/ (Category non-empty; path depth = 2)
foreach ($s in $skillSources) {
    if ([string]::IsNullOrEmpty($s.Category)) {
        Write-Host ("[FAIL] skill '{0}' is flat under skills/ — must be skills/<category>/{0}/" -f $s.Name)
        $failed = $true
        continue
    }
    $expected = Join-Path (Join-Path $skillsDir $s.Category) $s.Name
    if ($s.Path.TrimEnd('\') -ine $expected.TrimEnd('\')) {
        Write-Host ("[FAIL] skill '{0}' path not skills/{1}/{0}/: {2}" -f $s.Name, $s.Category, $s.Path)
        $failed = $true
    }
}
$categories = @($skillSources | ForEach-Object { $_.Category } | Where-Object { $_ } | Sort-Object -Unique)
Write-Host ("categories: {0}" -f ($categories -join ", "))

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

# name collisions / uniqueness — only log [ok] when discovery succeeded
if ($discoveryOk) {
    $overlap = $skillNames | Where-Object { $kitNames -contains $_ }
    if ($overlap) {
        Write-Host ("[FAIL] name collision skills↔kits: {0}" -f ($overlap -join ", "))
        $failed = $true
    }
    else {
        Write-Host "[ok]   unique install names (skills ↔ kits)"
    }

    $dupCheck = $skillNames | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupCheck) {
        Write-Host ("[FAIL] duplicate skill leaf names: {0}" -f (($dupCheck | ForEach-Object Name) -join ", "))
        $failed = $true
    }
    else {
        Write-Host "[ok]   unique skill leaf names"
    }
}
else {
    Write-Host "[skip] unique-name checks (discovery failed)"
}

# Dangling skills/… paths in active docs (not historical design archives)
$scanRoots = @(
    (Join-Path $repoRoot "README.md"),
    (Join-Path $repoRoot "docs\README.md"),
    (Join-Path $repoRoot "docs\workflows"),
    (Join-Path $repoRoot "docs\adr"),
    (Join-Path $repoRoot "docs\templates"),
    (Join-Path $repoRoot "kits"),
    (Join-Path $repoRoot "skills"),
    (Join-Path $repoRoot "tools")
)
$mdFiles = @()
foreach ($root in $scanRoots) {
    if (Test-Path $root -PathType Leaf) { $mdFiles += Get-Item $root }
    elseif (Test-Path $root) {
        $mdFiles += Get-ChildItem -Path $root -Recurse -Filter *.md -File |
            Where-Object { $_.FullName -notmatch '[\\/]_' }
    }
}
$dangling = @()
function Test-SkillPathCite {
    param(
        [string]$RawCite,
        [string]$FileRel,
        [string[]]$SkillNames,
        [string[]]$Categories,
        [string]$RepoRoot
    )
    $rel = ($RawCite -replace '/', '\')
    # Strip leading ../ from markdown relative hrefs → skills\...
    while ($rel.StartsWith('..\', [System.StringComparison]::Ordinal)) {
        $rel = $rel.Substring(3)
    }
    while ($rel.Length -gt 0) {
        $last = $rel[-1]
        if ($last -notin @('.', ',', ';', ':', ')', ']', '`', '"', "'")) { break }
        $rel = $rel.Substring(0, $rel.Length - 1)
    }
    $rel = $rel.TrimEnd('\', '/')
    if ($rel -notlike 'skills\*') { return $null }
    $after = $rel -replace '^skills\\', ''
    if ([string]::IsNullOrEmpty($after)) { return $null }
    $segs = @($after -split '\\')
    $firstSeg = $segs[0]

    if ($segs.Count -eq 1) {
        if ($SkillNames -contains $firstSeg) {
            return "$FileRel -> $RawCite"
        }
        if ($firstSeg -ne 'README.md' -and $firstSeg -ne '_template' -and ($Categories -notcontains $firstSeg)) {
            return $null
        }
    }
    $full = Join-Path $RepoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) {
        return "$FileRel -> $RawCite"
    }
    return $null
}

foreach ($f in $mdFiles) {
    $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $text) { continue }
    $fileRel = $f.FullName.Substring($repoRoot.Length).TrimStart('\', '/')
    # NOTE: do not name collections $matches — PowerShell -match overwrites that automatic variable.
    # (1) bare / backtick skills/… — skip .cursor/skills, URLs, my-skills/
    $pathHits = [regex]::Matches($text, '(?<![.:/\w-])skills/[A-Za-z0-9_][A-Za-z0-9_./-]*')
    # (2) markdown relative hrefs ](../skills/…) that lookbehind (1) misses
    $relHits = [regex]::Matches($text, '(?:\.\./)+skills/[A-Za-z0-9_][A-Za-z0-9_./-]*')
    $allHits = New-Object System.Collections.Generic.List[object]
    foreach ($h in $pathHits) { [void]$allHits.Add($h) }
    foreach ($h in $relHits) { [void]$allHits.Add($h) }
    foreach ($hit in $allHits) {
        $bad = Test-SkillPathCite -RawCite $hit.Value -FileRel $fileRel `
            -SkillNames $skillNames -Categories $categories -RepoRoot $repoRoot
        if ($bad) { $dangling += $bad }
    }
}
if ($dangling.Count -gt 0) {
    Write-Host "[FAIL] dangling skills/ paths:"
    $dangling | Select-Object -Unique | ForEach-Object { Write-Host "         $_" }
    $failed = $true
}
else {
    Write-Host "[ok]   no dangling skills/ paths in active docs"
}

# Optional: README Skills-cloud category labels ⊆ actual category dirs
$readme = Get-Content (Join-Path $repoRoot "README.md") -Raw
$cloudCats = @()
foreach ($label in @(
        @{ Re = '编排:'; Name = 'orchestration' },
        @{ Re = '设计:'; Name = 'design' },
        @{ Re = '质量:'; Name = 'quality' },
        @{ Re = '审查:'; Name = 'review' },
        @{ Re = '文档:'; Name = 'docs' },
        @{ Re = '前端:'; Name = 'frontend' },
        @{ Re = 'CI:'; Name = 'ci' }
    )) {
    if ($readme -match $label.Re) { $cloudCats += $label.Name }
}
$expectedCloud = @('orchestration', 'design', 'quality', 'review', 'docs', 'frontend', 'ci')
if ($cloudCats.Count -eq 0) {
    Write-Host "[FAIL] README cloud category labels missing (expected 编排:/设计:/…/CI:)"
    $failed = $true
}
else {
    $missingCat = $cloudCats | Where-Object { $categories -notcontains $_ }
    $missingLabels = $expectedCloud | Where-Object { $cloudCats -notcontains $_ }
    if ($missingCat) {
        Write-Host ("[FAIL] README cloud categories not on disk: {0}" -f ($missingCat -join ", "))
        $failed = $true
    }
    elseif ($missingLabels) {
        Write-Host ("[FAIL] README cloud missing labels: {0}" -f ($missingLabels -join ", "))
        $failed = $true
    }
    else {
        Write-Host ("[ok]   README cloud categories ⊆ disk ({0})" -f ($cloudCats -join ", "))
    }
}

# scan-skills gate (Critical patterns)
Write-Host ""
Write-Host "---- scan-skills ----"
$scan = Join-Path $PSScriptRoot "scan-skills.ps1"
$scanHost = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $scanHost) { $scanHost = Get-Command powershell }
& $scanHost.Source -NoProfile -ExecutionPolicy Bypass -File $scan -Path $repoRoot
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] scan-skills"
    $failed = $true
}
else {
    Write-Host "[ok]   scan-skills"
}

if ($failed) {
    Write-Host ""
    Write-Host "check-layout: FAILED"
    exit 1
}

# Optional install regression when present
$smoke = Join-Path $PSScriptRoot "smoke-install.ps1"
if (Test-Path $smoke) {
    Write-Host ""
    Write-Host "---- smoke-install ----"
    $smokeHost = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $smokeHost) { $smokeHost = Get-Command powershell }
    & $smokeHost.Source -NoProfile -ExecutionPolicy Bypass -File $smoke
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
