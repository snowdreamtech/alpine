# PowerShell wrapper for lint.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "lint.sh" ($args -join " ")
