# PowerShell wrapper for cleanup.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "cleanup.sh" $args
