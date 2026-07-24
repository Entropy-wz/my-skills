<#
.SYNOPSIS
    Query local SearXNG JSON API and print Markdown results for agents.
.EXAMPLE
    ./search.ps1 -Query "digital finance case study"
    ./search.ps1 -Query "数字金融 案例" -Language zh-CN -Count 8
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

    Write-Output ("查询: {0} | 语言: {1} | 命中: {2} 条 | 引擎: {3}" -f $QueryText, $Lang, $results.Count, $engineList)
    Write-Output ""

    if ($results.Count -eq 0) {
        Write-Output "(无结果。可改 language、换关键词，或检查引擎是否被上游限流。)"
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
        Write-Output ("   摘要: {0}" -f $snippet)
        Write-Output ("   来源引擎: {0}" -f $eng)
        Write-Output ""
        $i++
    }

    if ($Payload.suggestions -and @($Payload.suggestions).Count -gt 0) {
        $sug = (@($Payload.suggestions) | Select-Object -First 5) -join "; "
        Write-Output ("建议关键词: {0}" -f $sug)
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
    $msg = $_.Exception.Message
    if ($msg -match "Unable to connect|actively refused|No connection|无法连接|拒绝|未能解析|远程服务器") {
        Write-Error @"
SearXNG 未运行或无法连接 ($BaseUrl)。

请先执行:
  cd kits/searxng-search
  powershell -File tools/up.ps1

然后自检:
  curl `"http://127.0.0.1:8080/search?q=test&format=json`"
"@
        exit 2
    }
    if ($msg -match "403|Forbidden") {
        Write-Error "SearXNG 返回 403：多半未开启 JSON（settings 中 search.formats 需含 json）。改完后: docker compose restart"
        exit 3
    }
    Write-Error "SearXNG 请求失败: $msg"
    exit 1
}

Format-Results -Payload $resp -QueryText $Query -Lang $Language -Take $Count
exit 0
