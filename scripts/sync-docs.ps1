# scripts/sync-docs.ps1 - Documentation Sync Wrapper (PowerShell)
<#
.SYNOPSIS
    Provides a stable PowerShell entry point for the Python documentation sync logic.
.DESCRIPTION
    Delegates execution to the POSIX script via sh if available,
    or runs the Python script directly.
.EXAMPLE
    .\scripts\sync-docs.ps1
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\lib\common.ps1"

function Main {
    Log-Info "🔄 Synchronizing Rules and Workflows to Docs..."

    if (Get-Command "python3" -ErrorAction SilentlyContinue) {
        python3 "$ScriptDir\sync-docs.py"
    } elseif (Get-Command "python" -ErrorAction SilentlyContinue) {
        python "$ScriptDir\sync-docs.py"
    } else {
        Log-Error "Error: Python 3 not found."
        exit 1
    }

    Log-Success "`n✨ Documentation synchronization complete!"
}

Main
