# PowerShell wrapper for cleanup.sh
# Ensures that the POSIX shell script remains the single source of truth (SSoT).
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "cleanup.sh" $args
