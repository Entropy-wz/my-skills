<#
.SYNOPSIS
    将本仓库 skills/ 下的技能安装到个人 Cursor 技能目录 (~/.cursor/skills/)。
.DESCRIPTION
    默认创建符号链接（修改仓库即时生效）。加 -Copy 改为复制。
    以 _ 开头的目录（如 _template）会被跳过。
.EXAMPLE
    ./scripts/install.ps1
    ./scripts/install.ps1 -Copy
#>
param(
    [switch]$Copy
)

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $PSScriptRoot
$srcDir     = Join-Path $repoRoot "skills"
$destDir    = Join-Path $HOME ".cursor\skills"

if (-not (Test-Path $srcDir)) {
    Write-Error "找不到 skills 目录: $srcDir"
    exit 1
}

New-Item -ItemType Directory -Force -Path $destDir | Out-Null

Get-ChildItem -Path $srcDir -Directory | Where-Object { $_.Name -notlike "_*" } | ForEach-Object {
    $name = $_.Name
    $target = $_.FullName
    $link   = Join-Path $destDir $name

    if (Test-Path $link) {
        Remove-Item $link -Recurse -Force
    }

    if ($Copy) {
        Copy-Item -Path $target -Destination $link -Recurse
        Write-Host "[copied] $name"
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null
            Write-Host "[linked] $name"
        } catch {
            Write-Warning "创建符号链接失败（可能需要管理员权限或开发者模式），改为复制: $name"
            Copy-Item -Path $target -Destination $link -Recurse
            Write-Host "[copied] $name"
        }
    }
}

Write-Host ""
Write-Host "完成。技能已安装到: $destDir"
