# scripts/lib/common.ps1 - Shared logic for PowerShell wrappers.

function Delegate-To-Shell {
    param(
        [string]$ScriptName,
        [string]$Arguments
    )

    $ScriptPath = Join-Path $PSScriptRoot "..\" $ScriptName

    if (Get-Command 'sh' -ErrorAction SilentlyContinue) {
        sh "$ScriptPath" $Arguments
    }
    elseif (Get-Command 'bash' -ErrorAction SilentlyContinue) {
        bash "$ScriptPath" $Arguments
    }
    else {
        Write-Output "Error: 'sh' or 'bash' not found. Please install Git for Windows or ensure a POSIX shell is in your PATH."
        exit 1
    }
}
