# scripts/check-env.ps1 - PowerShell wrapper for scripts/check-env.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "check-env.sh" $args
