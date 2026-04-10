# PowerShell wrapper — delegates to benchmark-binary-resolution.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "benchmark-binary-resolution.sh" ($args -join " ")
