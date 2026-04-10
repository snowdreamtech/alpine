# PowerShell wrapper — delegates to analyze-cache-effectiveness.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "analyze-cache-effectiveness.sh" ($args -join " ")
