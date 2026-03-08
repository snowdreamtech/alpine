# PowerShell wrapper for archive-changelog.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "archive-changelog.sh" $args
