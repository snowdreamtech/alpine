# PowerShell wrapper — delegates to collect-baseline.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "collect-baseline.sh" ($args -join " ")
