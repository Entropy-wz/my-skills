<#
.SYNOPSIS
    Query local SearXNG JSON API and print Markdown results for agents.
.EXAMPLE
    ./search.ps1 -Query "digital finance case study"
    ./search.ps1 -Query "数字金融 案例" -Language zh-CN -Count 8
    ./search.ps1 -Query "same" -Refresh
    ./search.ps1 -Query "same" -NoCache
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Query,

    [string]$Language = "auto",

    [ValidateRange(1, 20)]
    [int]$Count = 8,

    [string]$Category = "general",

    [string]$BaseUrl = "http://127.0.0.1:8080",

    [int]$TimeoutSec = 10,

    [int]$CacheTtlHours = 24,

    [switch]$NoCache,

    [switch]$Refresh,

    # Client-side spacing between live SearXNG hits (0 = off). Cache hits skip this.
    [ValidateRange(0, 60)]
    [int]$MinIntervalSec = 1
)

$ErrorActionPreference = "Stop"

$kitRoot = Split-Path -Parent $PSScriptRoot
$cacheDir = Join-Path $kitRoot ".cache"
$throttleFile = Join-Path $cacheDir "last-live-request.txt"

function Get-CacheKey {
    param([string]$Q, [string]$Lang, [string]$Cat)
    $raw = "{0}`n{1}`n{2}" -f $Q, $Lang, $Cat
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    return ([System.BitConverter]::ToString($hash) -replace "-", "").ToLowerInvariant()
}

function Get-ResultCount {
    param($Payload)
    if (-not $Payload -or -not $Payload.results) { return 0 }
    return @($Payload.results).Count
}

function Test-ShouldCache {
    param($Payload)
    # Never pin empty / rate-limited empties for the full TTL.
    return (Get-ResultCount -Payload $Payload) -gt 0
}

function Format-Results {
    param($Payload, [string]$QueryText, [string]$Lang, [int]$Take, [string]$CacheNote)

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

    $cacheTag = if ($CacheNote) { " | cache=$CacheNote" } else { "" }
    Write-Output ("Query: {0} | Lang: {1} | Hits: {2} | Engines: {3}{4}" -f $QueryText, $Lang, $results.Count, $engineList, $cacheTag)
    Write-Output ""

    if ($results.Count -eq 0) {
        Write-Output "(No results. Try another language/keywords, or wait if upstream rate-limited.)"
        Write-Output ""
    }
    else {
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
    }

    if ($Payload.suggestions -and @($Payload.suggestions).Count -gt 0) {
        $sug = (@($Payload.suggestions) | Select-Object -First 5) -join "; "
        Write-Output ("Suggestions: {0}" -f $sug)
        Write-Output ""
    }

    $unresponsive = @()
    if ($Payload.unresponsive_engines) {
        foreach ($item in @($Payload.unresponsive_engines)) {
            if ($null -eq $item) { continue }
            if ($item -is [System.Array] -or $item -is [System.Collections.IList]) {
                $name = [string]$item[0]
                $err = if ($item.Count -gt 1) { [string]$item[1] } else { "" }
                if ($err) { $unresponsive += ("{0} ({1})" -f $name, $err) }
                else { $unresponsive += $name }
            }
            elseif ($item.PSObject.Properties["error"] -or $item.PSObject.Properties["engine"]) {
                $name = if ($item.engine) { [string]$item.engine } elseif ($item.name) { [string]$item.name } else { [string]$item }
                $err = if ($item.error) { [string]$item.error } else { "" }
                if ($err) { $unresponsive += ("{0} ({1})" -f $name, $err) }
                else { $unresponsive += $name }
            }
            else {
                $unresponsive += [string]$item
            }
        }
    }

    if ($unresponsive.Count -gt 0) {
        Write-Output ("Unresponsive engines: {0}" -f ($unresponsive -join "; "))
        Write-Output "Hint: wait for suspended_time, lower query rate, try -Language zh-CN/en, or opt-in engines in settings.yml (see kit README)."
    }
    elseif ($results.Count -eq 0) {
        Write-Output "Unresponsive engines: (none reported — try language switch or see kit README rate-limit playbook)"
    }
}

function Read-CacheEntry {
    param([string]$Path, [int]$TtlHours)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        $entry = $raw | ConvertFrom-Json
        if (-not $entry.ts -or -not $entry.payload) { return $null }
        $saved = [datetimeoffset]::Parse($entry.ts).UtcDateTime
        if (([datetime]::UtcNow - $saved).TotalHours -gt $TtlHours) { return $null }
        # Heal older empties that should never have been cached.
        if (-not (Test-ShouldCache -Payload $entry.payload)) { return $null }
        return $entry.payload
    }
    catch {
        return $null
    }
}

function Write-CacheEntry {
    param([string]$Path, $Payload)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $entry = [ordered]@{
        ts      = [datetime]::UtcNow.ToString("o")
        payload = $Payload
    }
    ($entry | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Wait-MinInterval {
    param([string]$Path, [int]$Seconds)
    if ($Seconds -le 0) { return }
    if (-not (Test-Path -LiteralPath $Path)) { return }
    try {
        $text = (Get-Content -LiteralPath $Path -Raw).Trim()
        $last = [datetimeoffset]::Parse($text).UtcDateTime
        $elapsed = ([datetime]::UtcNow - $last).TotalSeconds
        if ($elapsed -lt $Seconds) {
            $sleep = [math]::Ceiling($Seconds - $elapsed)
            Start-Sleep -Seconds $sleep
        }
    }
    catch {
        # ignore corrupt throttle file
    }
}

function Mark-LiveRequest {
    param([string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    [datetime]::UtcNow.ToString("o") | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-HttpStatusFromException {
    param($Exception, [string]$Message = "")
    $ex = $Exception
    while ($null -ne $ex) {
        $name = $ex.GetType().FullName
        # Avoid -is [HttpRequestException] — type missing on Windows PowerShell 5.1.
        if ($name -eq "System.Net.WebException") {
            $resp = $ex.Response
            if ($null -ne $resp) {
                try { return [int]$resp.StatusCode }
                catch { }
            }
        }
        # .NET Core / pwsh: HttpRequestException.StatusCode (nullable)
        if ($null -ne $ex.PSObject.Properties["StatusCode"] -and $null -ne $ex.StatusCode) {
            try { return [int]$ex.StatusCode }
            catch { }
        }
        $ex = $ex.InnerException
    }
    if ($Message -match "(?i)status code[^\d]*(\d{3})" -or $Message -match "\((\d{3})\)") {
        return [int]$Matches[1]
    }
    return $null
}

function Test-IsConnectivityFailure {
    param($Exception, [string]$Message)

    # If we already know an HTTP status, the instance answered — not "down".
    if ($null -ne (Get-HttpStatusFromException -Exception $Exception -Message $Message)) {
        return $false
    }

    $ex = $Exception
    while ($null -ne $ex) {
        $name = $ex.GetType().FullName
        if ($name -eq "System.Net.Sockets.SocketException") {
            return $true
        }
        if ($name -eq "System.Net.Http.HttpRequestException") {
            # Only treat as connectivity when no status was parsed above.
            return $true
        }
        if ($name -eq "System.Net.WebException") {
            if ($ex.Status -eq [System.Net.WebExceptionStatus]::ProtocolError) {
                return $false
            }
            return $true
        }
        $ex = $ex.InnerException
    }

    foreach ($pat in @(
            "Unable to connect",
            "actively refused",
            "No connection",
            "Failed to connect",
            "remote name could not be resolved",
            "无法连接",
            "未能解析",
            "远程服务器",
            "没有连接",
            "连接失败"
        )) {
        if ($Message -like ("*" + $pat + "*")) { return $true }
    }
    return $false
}

$cacheKey = Get-CacheKey -Q $Query -Lang $Language -Cat $Category
$cachePath = Join-Path $cacheDir ("{0}.json" -f $cacheKey)
$cacheNote = "miss"
$resp = $null

if (-not $NoCache -and -not $Refresh) {
    $cached = Read-CacheEntry -Path $cachePath -TtlHours $CacheTtlHours
    if ($null -ne $cached) {
        $resp = $cached
        $cacheNote = "hit"
        Write-Host "cache=hit" -ForegroundColor DarkGray
    }
}

if ($null -eq $resp) {
    Wait-MinInterval -Path $throttleFile -Seconds $MinIntervalSec

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
        $httpStatus = Get-HttpStatusFromException -Exception $_.Exception -Message $msg

        # HTTP responses first — never classify 403 as "unreachable".
        if ($httpStatus -eq 403 -or $msg -match "(?i)\b403\b|Forbidden") {
            Write-Host "ERROR: SearXNG returned 403: enable json in search.formats, then docker compose restart" -ForegroundColor Red
            exit 3
        }
        if ($null -ne $httpStatus) {
            Write-Host ("ERROR: SearXNG HTTP {0}: {1}" -f $httpStatus, $msg) -ForegroundColor Red
            exit 1
        }

        if (Test-IsConnectivityFailure -Exception $_.Exception -Message $msg) {
            Write-Host ("ERROR: SearXNG is not running or unreachable ({0}). Start: powershell -File tools/up.ps1 (from this skill/kit directory)" -f $BaseUrl) -ForegroundColor Red
            exit 2
        }

        Write-Host ("ERROR: SearXNG request failed: {0}" -f $msg) -ForegroundColor Red
        exit 1
    }

    Mark-LiveRequest -Path $throttleFile
    $cacheNote = if ($Refresh) { "refresh" } else { "miss" }
    Write-Host ("cache={0}" -f $cacheNote) -ForegroundColor DarkGray

    if (-not $NoCache -and (Test-ShouldCache -Payload $resp)) {
        try {
            Write-CacheEntry -Path $cachePath -Payload $resp
        }
        catch {
            Write-Host ("WARN: could not write cache: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        }
    }
    elseif (-not $NoCache) {
        Write-Host "cache=skip (empty results; not written)" -ForegroundColor DarkGray
    }
}

Format-Results -Payload $resp -QueryText $Query -Lang $Language -Take $Count -CacheNote $cacheNote
exit 0
