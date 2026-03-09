# scripts/env.ps1 - PowerShell wrapper for scripts/env.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "env.sh" $args
