# PowerShell wrapper for install.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "install.sh" ($args -join " ")
