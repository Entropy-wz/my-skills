<#
.SYNOPSIS
    Generate secret if needed and start SearXNG via docker compose.
#>
$ErrorActionPreference = "Stop"
$kitRoot = Split-Path -Parent $PSScriptRoot
$dockerDir = Join-Path $kitRoot "docker"

& (Join-Path $PSScriptRoot "ensure-secret.ps1")
Push-Location $dockerDir
try {
    docker compose up -d
    docker compose ps
    Write-Host ""
    Write-Host "Health check:"
    curl.exe -sS "http://127.0.0.1:8080/search?q=test&format=json" | Select-Object -First 1
}
finally {
    Pop-Location
}
