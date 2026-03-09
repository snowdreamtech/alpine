# scripts/docs.ps1 - PowerShell wrapper for scripts/docs.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "docs.sh" $args
