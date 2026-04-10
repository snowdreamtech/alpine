# PowerShell wrapper — delegates to analyze-performance-trends.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "analyze-performance-trends.sh" ($args -join " ")
