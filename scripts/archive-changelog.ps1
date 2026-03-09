# PowerShell wrapper for archive-changelog.sh
# Ensures that the POSIX shell script remains the single source of truth (SSoT).
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "archive-changelog.sh" $args
