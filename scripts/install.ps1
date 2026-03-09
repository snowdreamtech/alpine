# scripts/install.ps1 - PowerShell wrapper for scripts/install.sh
#
# Professional delegation to POSIX shell to maintain Single Source of Truth (SSoT).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "install.sh" $args
