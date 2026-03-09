# scripts/lib/common.ps1 - Shared utility library for PowerShell wrappers.
#
# Enables delegation from Windows to POSIX shell scripts while maintaining
# the Shell (.sh) scripts as the Single Source of Truth (SSoT).
#
# Features:
#   - POSIX Shell delegation (sh/bash detection).
#   - Uniform argument passthrough.

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
