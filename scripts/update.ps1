# scripts/update.ps1 - PowerShell wrapper for scripts/update.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "update.sh" $args
