# PowerShell wrapper for docs.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "docs.sh" ($args -join " ")
