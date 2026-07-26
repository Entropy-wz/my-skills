<#
.SYNOPSIS
    Install skills from this toolkit into ~/.cursor/skills/.
.DESCRIPTION
    Sources (ADR-001):
      1) skills/**/<leaf>/SKILL.md  (skip _*; install name = leaf)
      2) kits/<name>/skill/SKILL.md  (skip _*)
    Kits install SKILL.md at the dest root and also bring tools/, docker/,
    agents/, README.md from the kit root (so -Copy still finds tools/).
    Default: symlink (repo edits apply immediately). -Copy forces copy.
    On symlink failure (no Developer Mode / admin), falls back to copy.
.EXAMPLE
    ./scripts/install.ps1
    ./scripts/install.ps1 -Copy
#>
param(
    [switch]$Copy
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsDir = Join-Path $repoRoot "skills"
$kitsDir = Join-Path $repoRoot "kits"
$destDir = Join-Path $HOME ".cursor\skills"

. (Join-Path $PSScriptRoot "lib\SkillSources.ps1")

function Remove-SkillDest {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $item = Get-Item -LiteralPath $Path -Force
    $isReparse = [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
    if ($isReparse) {
        # Symlink / junction: delete the link only (do not recurse into the repo).
        $item.Delete()
        return
    }

    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Place-Path {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Copy
    )

    if ($Copy) {
        if (Test-Path -LiteralPath $Source -PathType Container) {
            Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
        }
        else {
            Copy-Item -LiteralPath $Source -Destination $Destination
        }
        return
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
    }
    catch {
        if (Test-Path -LiteralPath $Source -PathType Container) {
            Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
        }
        else {
            Copy-Item -LiteralPath $Source -Destination $Destination
        }
        return "copied-fallback"
    }
    return "linked"
}

function Install-SkillSource {
    param(
        [Parameter(Mandatory = $true)]$Source,
        [Parameter(Mandatory = $true)][string]$DestDir,
        [switch]$Copy
    )

    $link = Join-Path $DestDir $Source.Name
    Remove-SkillDest -Path $link

    if ($Source.Kind -eq "skill") {
        $mode = Place-Path -Source $Source.Path -Destination $link -Copy:$Copy
        if ($Copy -or $mode -eq "copied-fallback") {
            Write-Host "[copied] $($Source.Name)"
        }
        else {
            Write-Host "[linked] $($Source.Name)"
        }
        return
    }

    # kit: flatten skill/* to dest root; attach tools/docker/agents/README
    $kitRoot = $Source.Path
    $skillDir = Join-Path $kitRoot "skill"
    New-Item -ItemType Directory -Path $link | Out-Null

    $usedCopy = [bool]$Copy
    Get-ChildItem -LiteralPath $skillDir -Force | ForEach-Object {
        $destItem = Join-Path $link $_.Name
        $mode = Place-Path -Source $_.FullName -Destination $destItem -Copy:$Copy
        if ($mode -eq "copied-fallback") { $usedCopy = $true }
    }

    foreach ($sibling in @("tools", "docker", "agents", "README.md")) {
        $srcSibling = Join-Path $kitRoot $sibling
        if (Test-Path -LiteralPath $srcSibling) {
            $destSibling = Join-Path $link $sibling
            $mode = Place-Path -Source $srcSibling -Destination $destSibling -Copy:$Copy
            if ($mode -eq "copied-fallback") { $usedCopy = $true }
        }
    }

    $label = "kit:$($Source.Name)"
    if ($Copy -or $usedCopy) {
        Write-Host "[copied] $label"
    }
    else {
        Write-Host "[linked] $label"
    }
}

if (-not (Test-Path $skillsDir)) {
    Write-Error "找不到 skills 目录: $skillsDir"
    exit 1
}

New-Item -ItemType Directory -Force -Path $destDir | Out-Null

$sources = @(Get-SkillSources -SkillsDir $skillsDir -KitsDir $kitsDir)

if ($sources.Count -eq 0) {
    Write-Error "未发现任何可安装 skill（skills/*/SKILL.md 或 kits/*/skill/SKILL.md）"
    exit 1
}

$installed = @()
foreach ($src in $sources) {
    $dup = $installed | Where-Object { $_.Name -eq $src.Name } | Select-Object -First 1
    if ($dup) {
        Write-Warning ("Name conflict, skip {0}: {1} (already have {2} at {3})" -f $src.Kind, $src.Name, $dup.Kind, $dup.Path)
        continue
    }
    Install-SkillSource -Source $src -DestDir $destDir -Copy:$Copy
    $installed += $src
}

Write-Host ""
Write-Host "完成。技能已安装到: $destDir"
Write-Host ("已安装: {0} skill(s), {1} kit skill(s)" -f `
    @($installed | Where-Object Kind -eq "skill").Count, `
    @($installed | Where-Object Kind -eq "kit").Count)
