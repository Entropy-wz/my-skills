#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string] $Url,
    [ValidateRange(1, 600)]
    [int] $TimeoutSec = 15,
    [string] $ExpectContent = ""
)

$ErrorActionPreference = "Stop"
Write-Host "smoke-ui: GET $Url (timeout ${TimeoutSec}s)"

try {
    $resp = Invoke-WebRequest -Uri $Url -Method GET -MaximumRedirection 5 -TimeoutSec $TimeoutSec -UseBasicParsing
    $len = 0
    if ($null -ne $resp.RawContentLength -and $resp.RawContentLength -ge 0) {
        $len = [int]$resp.RawContentLength
    }
    elseif ($resp.Content) {
        $len = [Text.Encoding]::UTF8.GetByteCount([string]$resp.Content)
    }
    Write-Host "status=$($resp.StatusCode) length=$len"
    if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 400) {
        Write-Host "FAIL: bad status"
        exit 1
    }
    if ($len -le 0) {
        Write-Host "FAIL: empty body (UI smoke requires non-empty response)"
        exit 1
    }
    if ($ExpectContent -and ([string]$resp.Content -notlike "*$ExpectContent*")) {
        Write-Host "FAIL: body missing expected substring: $ExpectContent"
        exit 1
    }
    exit 0
}
catch {
    Write-Host "FAIL: $($_.Exception.Message)"
    exit 1
}
