# PowerShell wrapper for archive-changelog.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "archive-changelog.sh" ($args -join " ")
