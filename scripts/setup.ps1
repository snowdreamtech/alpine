# PowerShell wrapper for setup.sh
# Ensures that the POSIX shell script remains the single source of truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Delegate-To-Shell "setup.sh" ($args -join " ")
