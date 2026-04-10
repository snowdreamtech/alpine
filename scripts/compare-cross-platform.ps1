#!/usr/bin/env pwsh
# scripts/compare-cross-platform.ps1 - PowerShell wrapper for compare-cross-platform.sh

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ShScript = Join-Path $ScriptDir "compare-cross-platform.sh"

if (-not (Test-Path $ShScript)) {
    Write-Error "Shell script not found: $ShScript"
    exit 1
}

# Forward all arguments to the shell script
& bash $ShScript @args
exit $LASTEXITCODE
