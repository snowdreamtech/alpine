# scripts/bench.ps1 - PowerShell wrapper for scripts/bench.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "bench.sh" $args
