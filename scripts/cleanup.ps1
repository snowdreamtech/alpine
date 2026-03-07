# PowerShell wrapper for cleanup.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "cleanup.sh" ($args -join " ")
