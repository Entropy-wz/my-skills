<#
.SYNOPSIS
    Install skills from this toolkit into ~/.cursor/skills/.
.DESCRIPTION
    Sources:
      1) skills/<name>/SKILL.md  (skip _*)
      2) kits/<name>/skill/SKILL.md  (skip _*)
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

function Get-SkillSources {
    param(
        [string]$SkillsDir,
        [string]$KitsDir
    )

    $sources = @()

    if (Test-Path $SkillsDir) {
        Get-ChildItem -Path $SkillsDir -Directory |
            Where-Object { $_.Name -notlike "_*" } |
            ForEach-Object {
                $skillMd = Join-Path $_.FullName "SKILL.md"
                if (Test-Path $skillMd) {
                    $sources += [PSCustomObject]@{
                        Name = $_.Name
                        Path = $_.FullName
                        Kind = "skill"
                    }
                }
            }
    }

    if (Test-Path $KitsDir) {
        Get-ChildItem -Path $KitsDir -Directory |
            Where-Object { $_.Name -notlike "_*" } |
            ForEach-Object {
                $skillDir = Join-Path $_.FullName "skill"
                $skillMd = Join-Path $skillDir "SKILL.md"
                if (Test-Path $skillMd) {
                    $sources += [PSCustomObject]@{
                        Name = $_.Name
                        Path = $skillDir
                        Kind = "kit"
                    }
                }
            }
    }

    return $sources
}

function Install-SkillSource {
    param(
        [Parameter(Mandatory = $true)]$Source,
        [Parameter(Mandatory = $true)][string]$DestDir,
        [switch]$Copy
    )

    $link = Join-Path $DestDir $Source.Name

    if (Test-Path $link) {
        Remove-Item $link -Recurse -Force
    }

    $label = if ($Source.Kind -eq "kit") { "kit:$($Source.Name)" } else { $Source.Name }

    if ($Copy) {
        Copy-Item -Path $Source.Path -Destination $link -Recurse
        Write-Host "[copied] $label"
        return
    }

    try {
        New-Item -ItemType SymbolicLink -Path $link -Target $Source.Path | Out-Null
        Write-Host "[linked] $label"
    }
    catch {
        Write-Warning "创建符号链接失败（可能需要管理员权限或开发者模式），改为复制: $label"
        Copy-Item -Path $Source.Path -Destination $link -Recurse
        Write-Host "[copied] $label"
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
