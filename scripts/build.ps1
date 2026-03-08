# PowerShell wrapper for build.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "build.sh" $args
