<#
.SYNOPSIS
    Shared skill/kit discovery for install.ps1 and check-layout.ps1.
#>

function Get-SkillSources {
    param(
        [Parameter(Mandatory = $true)][string]$SkillsDir,
        [Parameter(Mandatory = $true)][string]$KitsDir
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
                $skillMd = Join-Path $_.FullName "skill\SKILL.md"
                if (Test-Path $skillMd) {
                    $sources += [PSCustomObject]@{
                        Name = $_.Name
                        Path = $_.FullName
                        Kind = "kit"
                    }
                }
            }
    }

    return $sources
}
