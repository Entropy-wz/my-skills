<#
.SYNOPSIS
    Fetch main text from URLs for research citation (Phase 2).
    Prefers Python trafilatura; falls back to lightweight HTML strip.
.NOTES
    PowerShell -File collapses -Url "a","b" into one arg "a,b".
    This script splits comma-joined http(s) URLs. Prefer repeated -Url.
.EXAMPLE
    ./fetch.ps1 -Url "https://example.com/a","https://example.com/b"
    powershell -File ./fetch.ps1 -Url "https://a.example,https://b.example"
#>
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Url,

    [int]$TimeoutSec = 10,

    [ValidateRange(500, 50000)]
    [int]$MaxChars = 4000,

    [ValidateRange(10000, 5000000)]
    [int]$MaxBytes = 1500000
)

$ErrorActionPreference = "Stop"

function Expand-UrlArgs {
    param([string[]]$Raw)
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($Raw)) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        $trimmed = $item.Trim().Trim('"').Trim("'")
        # -File turns -Url "a","b" into a single "a,b" argument
        $parts = [regex]::Split($trimmed, '\s*,\s*(?=https?://)')
        foreach ($p in $parts) {
            $u = $p.Trim().Trim('"').Trim("'")
            if ($u) { [void]$out.Add($u) }
        }
    }
    return , $out.ToArray()
}

function Invoke-NativeCapture {
    param([scriptblock]$Command)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & $Command 2>&1
        $code = $LASTEXITCODE
        $stdout = New-Object System.Collections.Generic.List[string]
        $stderr = New-Object System.Collections.Generic.List[string]
        foreach ($item in @($out)) {
            if ($item -is [System.Management.Automation.ErrorRecord]) {
                [void]$stderr.Add([string]$item)
            }
            else {
                [void]$stdout.Add([string]$item)
            }
        }
        return @{
            ExitCode = $code
            Output   = ($stdout -join "`n")
            Stderr   = ($stderr -join "`n")
        }
    }
    catch {
        return @{ ExitCode = 1; Output = ""; Stderr = [string]$_.Exception.Message }
    }
    finally {
        $ErrorActionPreference = $prev
    }
}

function Test-Trafilatura {
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
    if (-not $py) { return $false }
    $r = Invoke-NativeCapture -Command { & $py.Source -c "import trafilatura" }
    return ($r.ExitCode -eq 0)
}

function Get-TextViaTrafilatura {
    param(
        [string]$TargetUrl,
        [int]$Timeout,
        [int]$MaxLen,
        [int]$MaxB
    )
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command py }
    $code = @'
import sys
url = sys.argv[1]
timeout = int(sys.argv[2])
max_len = int(sys.argv[3])
max_bytes = int(sys.argv[4])
try:
    import trafilatura
    from trafilatura.settings import use_config
    config = use_config()
    config.set("DEFAULT", "DOWNLOAD_TIMEOUT", str(timeout))
    config.set("DEFAULT", "MAX_FILE_SIZE", str(max_bytes))
    downloaded = trafilatura.fetch_url(url, config=config)
    if not downloaded:
        sys.exit(2)
    if len(downloaded.encode("utf-8", errors="ignore")) > max_bytes:
        sys.stderr.write("response too large")
        sys.exit(3)
    text = trafilatura.extract(
        downloaded, include_comments=False, include_tables=False, config=config
    ) or ""
    text = text.strip()
    if len(text) > max_len:
        text = text[:max_len] + "\n...(truncated)"
    sys.stdout.write(text)
except Exception as e:
    sys.stderr.write(str(e))
    sys.exit(1)
'@
    $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("fetch-{0}.py" -f [guid]::NewGuid().ToString("n")))
    try {
        # UTF8 no BOM avoids python breaking on Windows PS 5.1 Set-Content -Encoding UTF8
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($tmp, $code, $utf8NoBom)
        $r = Invoke-NativeCapture -Command { & $py.Source $tmp $TargetUrl $Timeout $MaxLen $MaxB }
        if ($r.ExitCode -ne 0) {
            $err = if ($r.Stderr) { $r.Stderr } else { $r.Output }
            return @{ Ok = $false; Text = ""; Error = $err }
        }
        # Stdout only — never fold stderr warnings into the excerpt body.
        return @{ Ok = $true; Text = $r.Output; Error = "" }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

function Get-TextViaHtmlFallback {
    param([string]$TargetUrl, [int]$Timeout, [int]$MaxLen, [int]$MaxB)
    try {
        $resp = Invoke-WebRequest -Uri $TargetUrl -TimeoutSec $Timeout -MaximumRedirection 5 -UseBasicParsing
        $html = [string]$resp.Content
        $byteLen = [System.Text.Encoding]::UTF8.GetByteCount($html)
        if ($byteLen -gt $MaxB) {
            return @{ Ok = $false; Text = ""; Error = ("response too large ({0} bytes)" -f $byteLen) }
        }
        $html = [regex]::Replace($html, "(?is)<script[^>]*>.*?</script>", " ")
        $html = [regex]::Replace($html, "(?is)<style[^>]*>.*?</style>", " ")
        $html = [regex]::Replace($html, "(?is)<noscript[^>]*>.*?</noscript>", " ")
        $text = [regex]::Replace($html, "(?is)<[^>]+>", " ")
        $text = [System.Net.WebUtility]::HtmlDecode($text)
        $text = [regex]::Replace($text, "\s+", " ").Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            return @{ Ok = $false; Text = ""; Error = "empty after HTML strip" }
        }
        if ($text.Length -gt $MaxLen) {
            $text = $text.Substring(0, $MaxLen) + "`n...(truncated)"
        }
        return @{ Ok = $true; Text = $text; Error = "" }
    }
    catch {
        return @{ Ok = $false; Text = ""; Error = [string]$_.Exception.Message }
    }
}

$urls = Expand-UrlArgs -Raw $Url
if ($urls.Count -eq 0) {
    Write-Host "ERROR: no URLs after expanding -Url args" -ForegroundColor Red
    exit 1
}

$useTrafilatura = Test-Trafilatura
$extractor = if ($useTrafilatura) { "trafilatura" } else { "html-fallback" }

Write-Output ("Fetch: {0} URL(s) | extractor={1} | timeout={2}s | maxChars={3} | maxBytes={4}" -f `
        $urls.Count, $extractor, $TimeoutSec, $MaxChars, $MaxBytes)
Write-Output ""
Write-Output "Policy: research / citation use only. Prefer short excerpts; always cite the source URL."
Write-Output "Robots: this tool does not fetch or honor robots.txt. Use only for explicit user research; do not scrape at scale or ignore site terms."
Write-Output "Do not run tight fetch loops."
Write-Output ""

$i = 1
foreach ($u in $urls) {
    Write-Output ("--- [{0}] {1} ---" -f $i, $u)
    try {
        $result = $null
        if ($useTrafilatura) {
            $result = Get-TextViaTrafilatura -TargetUrl $u -Timeout $TimeoutSec -MaxLen $MaxChars -MaxB $MaxBytes
            if (-not $result.Ok) {
                $result = Get-TextViaHtmlFallback -TargetUrl $u -Timeout $TimeoutSec -MaxLen $MaxChars -MaxB $MaxBytes
                if ($result.Ok) {
                    Write-Output "extractor: html-fallback (trafilatura failed)"
                }
            }
            else {
                Write-Output "extractor: trafilatura"
            }
        }
        else {
            $result = Get-TextViaHtmlFallback -TargetUrl $u -Timeout $TimeoutSec -MaxLen $MaxChars -MaxB $MaxBytes
            Write-Output "extractor: html-fallback"
        }

        if ($result.Ok) {
            Write-Output ("Source: {0}" -f $u)
            Write-Output ""
            Write-Output $result.Text
        }
        else {
            Write-Output ("ERROR: {0}" -f $result.Error)
            Write-Output "(continuing batch)"
        }
    }
    catch {
        Write-Output ("ERROR: {0}" -f $_.Exception.Message)
        Write-Output "(continuing batch)"
    }
    Write-Output ""
    $i++
}

exit 0
