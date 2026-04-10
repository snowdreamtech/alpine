#!/usr/bin/env pwsh
# scripts/generate-profile-report.ps1 - PowerShell wrapper for generate-profile-report.sh

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ShScript = Join-Path $ScriptDir "generate-profile-report.sh"

if (-not (Test-Path $ShScript)) {
    Write-Error "Shell script not found: $ShScript"
    exit 1
}

# Forward all arguments to the shell script
& bash $ShScript @args
exit $LASTEXITCODE
