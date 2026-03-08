# PowerShell wrapper for env.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "env.sh" ($args -join " ")
