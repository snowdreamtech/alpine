# PowerShell wrapper for bench.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "bench.sh" ($args -join " ")
