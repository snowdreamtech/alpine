# PowerShell wrapper for audit.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "audit.sh" $args
