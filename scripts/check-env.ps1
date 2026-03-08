# PowerShell wrapper for check-env.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "check-env.sh" ($args -join " ")
