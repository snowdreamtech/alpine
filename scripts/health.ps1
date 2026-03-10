# scripts/health.ps1 - Windows Delegation Wrapper
# Powershell wrapper for health.sh

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CommonLib = Join-Path $ScriptDir "lib"
$CommonPs1 = Join-Path $CommonLib "common.ps1"

# Load common library for Invoke-ShellDelegation
if (Test-Path $CommonPs1) {
    . $CommonPs1
}

Invoke-ShellDelegation "health.sh" ($args -join " ")
