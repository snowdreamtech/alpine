# PowerShell wrapper for lint.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "lint.sh" ($args -join " ")
