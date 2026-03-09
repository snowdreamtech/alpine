# scripts/init-project.ps1 - PowerShell wrapper for scripts/init-project.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "init-project.sh" $args
