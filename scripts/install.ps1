# PowerShell wrapper for install.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "install.sh" ($args -join " ")
