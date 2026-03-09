# PowerShell wrapper for update.sh
# Ensures that the POSIX shell script remains the single source of truth (SSoT).
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "update.sh" $args
