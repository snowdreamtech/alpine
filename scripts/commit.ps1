# scripts/commit.ps1 - PowerShell wrapper for scripts/commit.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "commit.sh" $args
