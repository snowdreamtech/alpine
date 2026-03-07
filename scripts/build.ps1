# PowerShell wrapper for build.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "build.sh" ($args -join " ")
