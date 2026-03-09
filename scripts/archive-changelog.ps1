# scripts/archive-changelog.ps1 - PowerShell wrapper for scripts/archive-changelog.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "archive-changelog.sh" $args
