# PowerShell wrapper for format.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "format.sh" $args
