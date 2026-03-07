# PowerShell wrapper for check-env.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "check-env.sh" ($args -join " ")
