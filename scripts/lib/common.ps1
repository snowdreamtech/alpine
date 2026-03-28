# scripts/lib/common.ps1 - Shared utility library for PowerShell wrappers.
#
# Purpose:
#   Enables delegation from Windows to POSIX shell scripts while maintaining
#   the Shell (.sh) scripts as the Single Source of Truth (SSoT).
#
# Usage:
#   . "$PSScriptRoot/lib/common.ps1"
#
# Standards:
#   - PowerShell-native function patterns.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).
#
# Features:
#   - POSIX Shell delegation (sh/bash detection).
#   - Robust argument passthrough (@args splatting).

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

    # 1. Environment Hardening
    # Ensure errors fail fast in CI without interactive prompts
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    # 2. Path Resolution (SSoT)
    # Move one level up from lib/ to scripts/ to find the core .sh script.
    $ParentDir = Split-Path $PSScriptRoot -Parent
    $ScriptPath = Join-Path $ParentDir $ScriptName

    # 3. Execution Delegation
    if (Get-Command 'mise' -ErrorAction SilentlyContinue) {
        # Preferred: Use mise to load environment defined in .mise.toml
        mise x -- sh "$ScriptPath" @Arguments
    }
    elseif (Get-Command 'sh' -ErrorAction SilentlyContinue) {
        # POSIX shell found (typical for Git for Windows)
        sh "$ScriptPath" @Arguments
    }
    elseif (Get-Command 'bash' -ErrorAction SilentlyContinue) {
        # Alternative shell detection
        bash "$ScriptPath" @Arguments
    }
    else {
        Write-Error "Error: 'sh' or 'bash' not found. Please install Git for Windows or ensure a POSIX shell is in your PATH."
        exit 1
    }
}
