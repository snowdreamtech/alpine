# scripts/audit.ps1 - PowerShell wrapper for scripts/audit.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "audit.sh" $args
