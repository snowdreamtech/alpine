# scripts/lint.ps1 - PowerShell wrapper for scripts/lint.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "lint.sh" $args
