# PowerShell wrapper for init-project.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "init-project.sh" $args
