# scripts/verify.ps1 - PowerShell wrapper for scripts/verify.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "verify.sh" $args
