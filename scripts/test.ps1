# scripts/test.ps1 - PowerShell wrapper for scripts/test.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "test.sh" $args
