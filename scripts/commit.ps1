# PowerShell wrapper for commit.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "commit.sh" ($args -join " ")
