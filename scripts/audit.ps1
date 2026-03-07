# PowerShell wrapper for audit.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "audit.sh" ($args -join " ")
