# scripts/release.ps1 - PowerShell wrapper for scripts/release.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "release.sh" $args
