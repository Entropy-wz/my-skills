#Requires -Version 5.1
param(
    [string]$Path = "",
    [switch]$Json,
    [switch]$DryRun,
    [int]$TimeoutSec = 900
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$Start) {
    if ($Start) {
        # Explicit path: use it as the repo root directly (no upward walk).
        if (-not (Test-Path -LiteralPath $Start)) { throw "Path not found: $Start" }
        return (Resolve-Path -LiteralPath $Start).Path
    }
    # No path: walk up from cwd to the nearest .git root, else cwd.
    $start = (Get-Location).Path
    $cur = $start
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $cur ".git")) { return $cur }
        $parent = Split-Path -Parent $cur
        if (-not $parent -or $parent -eq $cur) { return $start }
        $cur = $parent
    }
}

function Get-PackageScripts([string]$Repo) {
    $pkg = Join-Path $Repo "package.json"
    if (-not (Test-Path -LiteralPath $pkg)) { return @() }
    try {
        $j = Get-Content -LiteralPath $pkg -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch { return @() }
    $names = @()
    if ($j.scripts) {
        foreach ($n in @("lint", "typecheck", "test")) {
            if ($j.scripts.PSObject.Properties.Name -contains $n) { $names += $n }
        }
    }
    return $names
}

function Test-MakeTarget([string]$Repo, [string]$Target) {
    $mf = Join-Path $Repo "Makefile"
    if (-not (Test-Path -LiteralPath $mf)) { return $false }
    $raw = Get-Content -LiteralPath $mf -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $false }
    return [bool]($raw -match ("(?m)^\s*" + [regex]::Escape($Target) + "\s*:"))
}

function Find-GateCommands([string]$Repo) {
    # Build every candidate into one list; return .ToArray() (no unary comma).
    # An empty list must yield a 0-length array so the caller's exit-4 path fires.
    $list = New-Object System.Collections.Generic.List[object]

    $gatesPs1 = Join-Path $Repo "scripts\gates.ps1"
    $gatesSh = Join-Path $Repo "scripts\gates.sh"
    if (Test-Path -LiteralPath $gatesPs1) {
        $list.Add(@{ Display = "powershell -File scripts/gates.ps1"; File = $gatesPs1; Kind = "ps1" })
        return $list.ToArray()
    }
    if (Test-Path -LiteralPath $gatesSh) {
        $list.Add(@{ Display = "bash scripts/gates.sh"; File = $gatesSh; Kind = "sh" })
        return $list.ToArray()
    }

    foreach ($n in (Get-PackageScripts -Repo $Repo)) {
        $list.Add(@{ Display = "npm run $n"; Kind = "npm"; NpmScript = $n })
    }
    foreach ($t in @("lint", "test", "check")) {
        if (Test-MakeTarget -Repo $Repo -Target $t) {
            $list.Add(@{ Display = "make $t"; Kind = "make"; MakeTarget = $t })
        }
    }
    $cl = Join-Path $Repo "scripts\check-layout.ps1"
    if (Test-Path -LiteralPath $cl) {
        $list.Add(@{ Display = "powershell -File scripts/check-layout.ps1"; File = $cl; Kind = "ps1" })
    }
    return $list.ToArray()
}

function Invoke-OneGate {
    param($Gate, [string]$Repo, [int]$TimeoutSec)

    # Resolve exe + args up front so MISSING_RUNTIME is reported without spawning
    # a job. Always use the resolved .Source (npm is npm.cmd on Windows).
    $exe = $null
    $cmdArgs = @()
    switch ($Gate.Kind) {
        "ps1" {
            $ps = Get-Command powershell.exe -ErrorAction SilentlyContinue
            if (-not $ps) { return @{ Exit = 2; Seconds = 0; Log = "powershell.exe not found"; MissingRuntime = $true } }
            $exe = $ps.Source
            $cmdArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Gate.File)
        }
        "sh" {
            $bash = $null
            foreach ($c in @("C:\Program Files\Git\bin\bash.exe", "bash")) {
                $g = Get-Command $c -ErrorAction SilentlyContinue
                if ($g) { $bash = $g.Source; break }
            }
            if (-not $bash) { return @{ Exit = 2; Seconds = 0; Log = "bash not found"; MissingRuntime = $true } }
            $exe = $bash
            $cmdArgs = @($Gate.File)
        }
        "npm" {
            $npm = Get-Command npm -ErrorAction SilentlyContinue
            if (-not $npm) { return @{ Exit = 2; Seconds = 0; Log = "npm not found"; MissingRuntime = $true } }
            $exe = $npm.Source
            $cmdArgs = @("run", $Gate.NpmScript)
        }
        "make" {
            $make = Get-Command make -ErrorAction SilentlyContinue
            if (-not $make) { return @{ Exit = 2; Seconds = 0; Log = "make not found"; MissingRuntime = $true } }
            $exe = $make.Source
            $cmdArgs = @($Gate.MakeTarget)
        }
        default { return @{ Exit = 1; Seconds = 0; Log = "unknown gate kind: $($Gate.Kind)"; MissingRuntime = $false } }
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # Run the command in a background job so Wait-Job can enforce a timeout.
    # Inside the job, ErrorActionPreference=Continue keeps a native tool's stderr
    # from raising a terminating NativeCommandError (the 5.1 stderr+Stop pitfall);
    # 2>&1 | Out-String then captures stdout+stderr as plain text.
    $job = Start-Job -ScriptBlock {
        param($wd, $exe, $cmdArgs)
        Set-Location -LiteralPath $wd
        $ErrorActionPreference = "Continue"
        $out = & $exe @cmdArgs 2>&1 | Out-String
        [pscustomobject]@{ Exit = $LASTEXITCODE; Log = $out }
    } -ArgumentList $Repo, $exe, $cmdArgs

    if (-not (Wait-Job -Job $job -Timeout $TimeoutSec)) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        return @{ Exit = 1; Seconds = [int]$sw.Elapsed.TotalSeconds; Log = "TIMEOUT after ${TimeoutSec}s"; MissingRuntime = $false }
    }

    $res = Receive-Job -Job $job
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    $exitCode = 1
    $log = ""
    if ($res) { $exitCode = [int]$res.Exit; $log = [string]$res.Log }
    return @{ Exit = $exitCode; Seconds = [int]$sw.Elapsed.TotalSeconds; Log = $log; MissingRuntime = $false }
}

$repo = Resolve-RepoRoot -Start $Path
$gates = @(Find-GateCommands -Repo $repo)
$when = [datetime]::UtcNow.ToString("o")

if ($gates.Count -eq 0) {
    Write-Output "## Gate results"
    Write-Output ("- env: {0} | repo: {1} | when: {2}" -f $env:OS, $repo, $when)
    Write-Output "- ran: (none)"
    Write-Output "- summary: NO GATES (exit 4)"
    if ($Json) {
        @{ repo = $repo; when = $when; commands = @(); summary = "NO_GATES" } | ConvertTo-Json -Compress
    }
    exit 4
}

if ($DryRun) {
    Write-Output "## Gate results (DryRun)"
    Write-Output ("- env: {0} | repo: {1} | when: {2}" -f $env:OS, $repo, $when)
    Write-Output "- ran:"
    # Single-quoted format string so backticks stay literal (markdown code spans).
    foreach ($g in $gates) { Write-Output ('  - `{0}` -> (dry-run)' -f $g.Display) }
    Write-Output ("- summary: DRY-RUN ({0} planned)" -f $gates.Count)
    exit 0
}

$results = @()
$anyFail = $false
$anyMissing = $false
foreach ($g in $gates) {
    $r = Invoke-OneGate -Gate $g -Repo $repo -TimeoutSec $TimeoutSec
    $status = if ($r.MissingRuntime) { "MISSING_RUNTIME" } elseif ($r.Exit -eq 0) { "PASS" } else { "FAIL" }
    if ($r.MissingRuntime) { $anyMissing = $true }
    elseif ($r.Exit -ne 0) { $anyFail = $true }
    $results += @{ cmd = $g.Display; status = $status; seconds = $r.Seconds; exit = $r.Exit; log = $r.Log }
}

Write-Output "## Gate results"
Write-Output ("- env: {0} | repo: {1} | when: {2}" -f $env:OS, $repo, $when)
Write-Output "- ran:"
foreach ($r in $results) {
    Write-Output ('  - `{0}` -> {1} ({2}s)' -f $r.cmd, $r.status, $r.seconds)
}
$sum = if ($anyMissing) { "MISSING_RUNTIME" } elseif ($anyFail) { "FAIL" } else { "PASS" }
Write-Output ("- summary: {0} ({1} ran)" -f $sum, $results.Count)

foreach ($r in $results) {
    if ($r.status -eq "FAIL" -or $r.status -eq "MISSING_RUNTIME") {
        $lines = @($r.log -split '\r?\n')
        $tail = $lines | Select-Object -Last 30
        Write-Output ""
        Write-Output ("### Log tail: {0}" -f $r.cmd)
        $tail | ForEach-Object { Write-Output $_ }
    }
}

if ($Json) {
    $payload = @{
        repo     = $repo
        when     = $when
        commands = @($results | ForEach-Object { @{ cmd = $_.cmd; status = $_.status; seconds = $_.seconds; exit = $_.exit } })
        summary  = $sum
    }
    $payload | ConvertTo-Json -Compress -Depth 5
}

if ($anyMissing) { exit 2 }
if ($anyFail) { exit 1 }
exit 0
