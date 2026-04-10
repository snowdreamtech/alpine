# PowerShell wrapper — delegates to compare-performance.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "compare-performance.sh" ($args -join " ")
