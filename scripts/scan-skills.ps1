#Requires -Version 5.1
<#
.SYNOPSIS
  Lightweight skill-scanner for skills/** and kits/**/skill/** SKILL.md files.
.DESCRIPTION
  Grep-style checks for exfil / ignore-previous / unbounded curl|sh / silent push / git config.
  Exit 0 = clean or warnings only; exit 1 = Critical pattern hit.
#>
param(
    [string] $Path = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = if ($Path) { (Resolve-Path -LiteralPath $Path).Path } else { Split-Path -Parent $PSScriptRoot }

$files = @()
$skills = Join-Path $repoRoot "skills"
if (Test-Path $skills) {
    $files += Get-ChildItem -Path $skills -Recurse -Filter SKILL.md -File |
        Where-Object { $_.FullName -notmatch '[\\/]_' }
}
$kits = Join-Path $repoRoot "kits"
if (Test-Path $kits) {
    $files += Get-ChildItem -Path $kits -Recurse -Filter SKILL.md -File |
        Where-Object { $_.FullName -match '[\\/]skill[\\/]SKILL\.md$' -and $_.FullName -notmatch '[\\/]_' }
}

$critical = @(
    @{ Name = "ignore-previous"; Re = 'ignore (all )?(previous|prior) (instructions|prompts)' },
    @{ Name = "curl-pipe-sh"; Re = 'curl[^\n]*\|\s*(ba)?sh' },
    @{ Name = "wget-pipe-sh"; Re = 'wget[^\n]*\|\s*(ba)?sh' },
    @{ Name = "exfil-env"; Re = '(exfiltrat|send (all )?(secrets|env|credentials)|upload.*(API_KEY|SECRET))' },
    @{ Name = "silent-force-push"; Re = 'git\s+push\s+[^\n]*--force[^\n]*without' },
    @{ Name = "git-config-rewrite"; Re = 'git\s+config\s+(--global\s+)?user\.(email|name)' }
)

$hits = @()
foreach ($f in $files) {
    $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $text) { continue }
    foreach ($c in $critical) {
        if ($text -imatch $c.Re) {
            $rel = $f.FullName.Substring($repoRoot.Length).TrimStart('\', '/')
            $hits += [pscustomobject]@{ Severity = "Critical"; Check = $c.Name; File = $rel }
        }
    }
}

if ($hits.Count -eq 0) {
    Write-Host "scan-skills: OK ($($files.Count) files)"
    exit 0
}

Write-Host "scan-skills: FINDINGS"
$hits | Format-Table -AutoSize | Out-String | Write-Host
exit 1
