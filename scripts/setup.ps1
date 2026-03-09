# scripts/setup.ps1 - PowerShell wrapper for scripts/setup.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "setup.sh" $args
