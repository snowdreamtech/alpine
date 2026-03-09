# scripts/build.ps1 - PowerShell wrapper for scripts/build.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "build.sh" $args
