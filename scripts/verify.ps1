# PowerShell wrapper for verify.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "verify.sh" ($args -join " ")
