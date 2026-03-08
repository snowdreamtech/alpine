# PowerShell wrapper for commit.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "commit.sh" $args
