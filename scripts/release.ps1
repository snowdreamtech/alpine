# PowerShell wrapper for release.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "release.sh" ($args -join " ")
