# PowerShell wrapper for release.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "release.sh" ($args -join " ")
