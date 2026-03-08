# PowerShell wrapper for docs.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "docs.sh" ($args -join " ")
