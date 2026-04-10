#!/usr/bin/env pwsh
# scripts/validate-doc-examples.ps1 - PowerShell wrapper for validate-doc-examples.sh

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ShScript = Join-Path $ScriptDir "validate-doc-examples.sh"

if (-not (Test-Path $ShScript)) {
    Write-Error "Shell script not found: $ShScript"
    exit 1
}

# Forward all arguments to the shell script
& bash $ShScript @args
exit $LASTEXITCODE
