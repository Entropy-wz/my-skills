<#
.SYNOPSIS
    Query local SearXNG JSON API and print Markdown results for agents.
.EXAMPLE
    ./search.ps1 -Query "digital finance case study"
    ./search.ps1 -Query "鏁板瓧閲戣瀺 妗堜緥" -Language zh-CN -Count 8
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Query,

    [string]$Language = "auto",

    [ValidateRange(1, 20)]
    [int]$Count = 8,

    [string]$Category = "general",

    [string]$BaseUrl = "http://127.0.0.1:8080",

    [int]$TimeoutSec = 10
)

$ErrorActionPreference = "Stop"

function Format-Results {
    param($Payload, [string]$QueryText, [string]$Lang, [int]$Take)

    $results = @()
    if ($Payload.results) {
        $results = @($Payload.results | Select-Object -First $Take)
    }

    $engines = @()
    foreach ($r in $results) {
        if ($r.engine) { $engines += [string]$r.engine }
        elseif ($r.engines) { $engines += @($r.engines | ForEach-Object { "$_" }) }
    }
    $engineList = ($engines | Select-Object -Unique) -join ","
    if (-not $engineList) { $engineList = "(unknown)" }

    Write-Output ("Query: {0} | Lang: {1} | Hits: {2} | Engines: {3}" -f $QueryText, $Lang, $results.Count, $engineList)
    Write-Output ""

    if ($results.Count -eq 0) {
        Write-Output "(No results. Try another language/keywords, or wait if upstream rate-limited.)"
        return
    }

    $i = 1
    foreach ($r in $results) {
        $title = if ($r.title) { [string]$r.title } else { "(no title)" }
        $url = if ($r.url) { [string]$r.url } else { "" }
        $snippet = if ($r.content) { [string]$r.content } elseif ($r.snippet) { [string]$r.snippet } else { "" }
        $eng = if ($r.engine) { [string]$r.engine } elseif ($r.engines) { (@($r.engines) -join ",") } else { "" }

        Write-Output ("{0}. {1}" -f $i, $title)
        Write-Output ("   URL: {0}" -f $url)
        Write-Output ("   Snippet: {0}" -f $snippet)
        Write-Output ("   Engine: {0}" -f $eng)
        Write-Output ""
        $i++
    }

    if ($Payload.suggestions -and @($Payload.suggestions).Count -gt 0) {
        $sug = (@($Payload.suggestions) | Select-Object -First 5) -join "; "
        Write-Output ("Suggestions: {0}" -f $sug)
    }
}

$encoded = [uri]::EscapeDataString($Query)
$langEnc = [uri]::EscapeDataString($Language)
$catEnc = [uri]::EscapeDataString($Category)
$uri = "{0}/search?q={1}&format=json&language={2}&categories={3}&safesearch=0&pageno=1" -f `
    $BaseUrl.TrimEnd("/"), $encoded, $langEnc, $catEnc

try {
    $resp = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec $TimeoutSec
}
catch {
    $msg = [string]$_.Exception.Message
    $isDown = $false
    foreach ($pat in @(
            "Unable to connect",
            "actively refused",
            "No connection",
            "Failed to connect",
            "remote name could not be resolved"
        )) {
        if ($msg -like ("*" + $pat + "*")) { $isDown = $true; break }
    }
    # Chinese Windows often uses localized connect errors
    if ($msg -match "[\u65e0\u6cd5\u8fde\u63a5]|[\u62d2\u7edd]|[\u8fdc\u7a0b\u670d\u52a1\u5668]") {
        $isDown = $true
    }

    if ($isDown) {
        Write-Host ("ERROR: SearXNG is not running or unreachable ({0}). Start: powershell -File kits/searxng-search/tools/up.ps1" -f $BaseUrl) -ForegroundColor Red
        exit 2
    }
    if ($msg -match "403|Forbidden") {
        Write-Host "ERROR: SearXNG returned 403: enable json in search.formats, then docker compose restart" -ForegroundColor Red
        exit 3
    }
    Write-Host ("ERROR: SearXNG request failed: {0}" -f $msg) -ForegroundColor Red
    exit 1
}

Format-Results -Payload $resp -QueryText $Query -Lang $Language -Take $Count
exit 0
