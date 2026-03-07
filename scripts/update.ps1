# PowerShell wrapper for update.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "update.sh" ($args -join " ")
