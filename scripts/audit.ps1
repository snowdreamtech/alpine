# PowerShell wrapper for audit.sh
# Ensures that the POSIX shell script remains the single source of truth (SSoT).
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "audit.sh" $args
