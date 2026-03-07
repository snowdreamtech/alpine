# PowerShell wrapper for init-project.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "init-project.sh" ($args -join " ")
