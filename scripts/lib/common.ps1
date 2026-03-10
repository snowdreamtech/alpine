# scripts/lib/common.ps1 - Shared utility library for PowerShell wrappers.
#
# Enables delegation from Windows to POSIX shell scripts while maintaining
# the Shell (.sh) scripts as the Single Source of Truth (SSoT).
#
# Features:
#   - POSIX Shell delegation (sh/bash detection).
#   - Uniform argument passthrough.

<#
.SYNOPSIS
    Facilitates professional delegation from Windows to POSIX shell scripts.

.DESCRIPTION
    Maintains the Shell (.sh) scripts as the Single Source of Truth (SSoT) by
    detecting a POSIX shell (sh or bash) and passing all arguments through.

.PARAMETER ScriptName
    The name of the core .sh script to invoke (e.g., "setup.sh").

.PARAMETER Arguments
    The array of command-line arguments to pass through to the shell script.

.EXAMPLE
    Invoke-ShellDelegation "setup.sh" $args
#>
function Invoke-ShellDelegation {
    param(
        [string]$ScriptName,
        [string[]]$Arguments
    )

    $ScriptPath = Join-Path $PSScriptRoot "..\" $ScriptName

    if (Get-Command 'sh' -ErrorAction SilentlyContinue) {
        sh "$ScriptPath" @Arguments
    }
    elseif (Get-Command 'bash' -ErrorAction SilentlyContinue) {
        bash "$ScriptPath" @Arguments
    }
    else {
        Write-Output "Error: 'sh' or 'bash' not found. Please install Git for Windows or ensure a POSIX shell is in your PATH."
        exit 1
    }
}
