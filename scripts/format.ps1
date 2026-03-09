# scripts/format.ps1 - PowerShell wrapper for scripts/format.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "format.sh" $args
