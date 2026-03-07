# PowerShell wrapper for format.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "format.sh" ($args -join " ")
