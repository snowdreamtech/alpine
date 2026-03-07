# PowerShell wrapper for env.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "env.sh" ($args -join " ")
