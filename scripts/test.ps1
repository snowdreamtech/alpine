# PowerShell wrapper for test.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "test.sh" $args
