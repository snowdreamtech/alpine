# PowerShell wrapper for verify.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "verify.sh" ($args -join " ")
