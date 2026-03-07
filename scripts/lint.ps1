# PowerShell wrapper for lint.sh
# Ensures that the POSIX shell script remains the single source of truth (SSoT).

$ArgsString = $args -join " "

if (Get-Command 'sh' -ErrorAction SilentlyContinue) {
    sh "$PSScriptRoot/lint.sh" $ArgsString
}
elseif (Get-Command 'bash' -ErrorAction SilentlyContinue) {
    bash "$PSScriptRoot/lint.sh" $ArgsString
}
else {
    Write-Output "Error: 'sh' or 'bash' not found. Please install Git for Windows or ensure a POSIX shell is in your PATH."
    exit 1
}
