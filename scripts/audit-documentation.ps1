# PowerShell wrapper — delegates to audit-documentation.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "audit-documentation.sh" ($args -join " ")
