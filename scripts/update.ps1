# PowerShell wrapper for update.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "update.sh" $args
