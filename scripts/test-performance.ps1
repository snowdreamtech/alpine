# PowerShell wrapper — delegates to test-performance.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "test-performance.sh" ($args -join " ")
