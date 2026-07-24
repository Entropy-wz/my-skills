<#
.SYNOPSIS
    Create docker/searxng/settings.yml from the example and set a random secret_key.
#>
$ErrorActionPreference = "Stop"

$kitRoot = Split-Path -Parent $PSScriptRoot
$example = Join-Path $kitRoot "docker\searxng\settings.example.yml"
$settings = Join-Path $kitRoot "docker\searxng\settings.yml"

if (-not (Test-Path $example)) {
    Write-Error "Missing settings.example.yml: $example"
    exit 1
}

if (-not (Test-Path $settings)) {
    Copy-Item -Path $example -Destination $settings
    Write-Host "Created settings.yml from example"
}

$text = Get-Content -Path $settings -Raw
if ($text -notmatch 'secret_key:\s*"REPLACE_ME_RUN_ensure-secret"') {
    Write-Host "secret_key already set — skip"
    exit 0
}

$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 32
$rng.GetBytes($bytes)
$rng.Dispose()
$secret = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
$updated = $text -replace 'secret_key:\s*"REPLACE_ME_RUN_ensure-secret"', "secret_key: `"$secret`""
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($settings, ($updated -replace "`r`n", "`n"), $utf8)
Write-Host "Wrote secret_key into local settings.yml (gitignored)"
