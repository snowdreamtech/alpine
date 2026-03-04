# PowerShell wrapper for init-project.sh
# This ensures that the POSIX shell script is the single source of truth.

if (Get-Command "sh" -ErrorAction SilentlyContinue) {
    sh "$PSScriptRoot/init-project.sh"
} else {
    Write-Host "Error: 'sh' (POSIX Shell) not found. Please install Git for Windows or ensure 'sh' is in your PATH." -ForegroundColor Red
    exit 1
}
