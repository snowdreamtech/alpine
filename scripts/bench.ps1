# PowerShell wrapper for bench.sh
. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "bench.sh" ($args -join " ")
