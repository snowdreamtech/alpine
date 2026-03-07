# PowerShell wrapper for test.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "test.sh" ($args -join " ")
