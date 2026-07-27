<#
.SYNOPSIS
    Shared skill/kit discovery for install.ps1 and check-layout.ps1.

.NOTES
    Repo layout (ADR-001): exactly skills/<category>/<leaf>/SKILL.md.
    Install name = leaf folder name (flat under ~/.cursor/skills/).
    Rejects skills-root, category-root, and depth>2 SKILL.md paths.
#>

function Get-SkillSources {
    param(
        [Parameter(Mandatory = $true)][string]$SkillsDir,
        [Parameter(Mandatory = $true)][string]$KitsDir
    )

    $sources = @()
    $seen = @{}
    $skillsRoot = (Resolve-Path -LiteralPath $SkillsDir).Path

    if (Test-Path $SkillsDir) {
        Get-ChildItem -Path $SkillsDir -Recurse -Filter SKILL.md -File |
            Where-Object {
                $rel = $_.FullName.Substring($SkillsDir.Length).TrimStart('\', '/')
                -not ($rel -match '(^|[\\/])_')
            } |
            ForEach-Object {
                $rel = $_.FullName.Substring($SkillsDir.Length).TrimStart('\', '/')
                $parts = @($rel -split '[\\/]')
                # Exactly category/leaf/SKILL.md
                if ($parts.Count -ne 3 -or $parts[2] -ne 'SKILL.md') {
                    throw "Invalid skill path '$rel': require skills/<category>/<leaf>/SKILL.md (ADR-001)"
                }
                $category = $parts[0]
                $name = $parts[1]
                $skillDir = $_.Directory.FullName

                # Belt: leaf parent must be category under skills root
                $parentOfLeaf = $_.Directory.Parent
                if ($null -eq $parentOfLeaf -or $parentOfLeaf.FullName -ne (Join-Path $skillsRoot $category)) {
                    throw "Invalid skill path '$rel': category/leaf nesting mismatch"
                }

                if ($seen.ContainsKey($name)) {
                    throw "Duplicate skill leaf name '$name': $($seen[$name]) and $skillDir"
                }
                $seen[$name] = $skillDir
                $sources += [PSCustomObject]@{
                    Name     = $name
                    Path     = $skillDir
                    Kind     = "skill"
                    Category = $category
                }
            }
    }

    if (Test-Path $KitsDir) {
        Get-ChildItem -Path $KitsDir -Directory |
            Where-Object { $_.Name -notlike "_*" } |
            ForEach-Object {
                $skillMd = Join-Path $_.FullName "skill\SKILL.md"
                if (Test-Path $skillMd) {
                    $name = $_.Name
                    if ($seen.ContainsKey($name)) {
                        throw "Duplicate install name '$name' between skills and kits"
                    }
                    $seen[$name] = $_.FullName
                    $sources += [PSCustomObject]@{
                        Name     = $name
                        Path     = $_.FullName
                        Kind     = "kit"
                        Category = ""
                    }
                }
            }
    }

    return $sources
}
