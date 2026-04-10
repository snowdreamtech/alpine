#!/usr/bin/env pwsh
# scripts/generate-tool-docs.ps1 - PowerShell wrapper for generate-tool-docs.sh

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ShScript = Join-Path $ScriptDir "generate-tool-docs.sh"

if (-not (Test-Path $ShScript)) {
    Write-Error "Shell script not found: $ShScript"
    exit 1
}

# Forward all arguments to the shell script
& bash $ShScript @args
exit $LASTEXITCODE
