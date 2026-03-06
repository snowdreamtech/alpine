<#
.SYNOPSIS
    Automates major-version changelog archiving by calling the POSIX shell script.
.DESCRIPTION
    Ensures a POSIX shell is available and executes scripts/archive-changelog.sh.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir = Split-Path -Parent $ScriptDir
$ShellScript = Join-Path $ScriptDir "archive-changelog.sh"

# Check for common POSIX shells
$Shell = "sh"
if (-not (Get-Command $Shell -ErrorAction SilentlyContinue)) {
    $Shell = "bash"
    if (-not (Get-Command $Shell -ErrorAction SilentlyContinue)) {
        Write-Error "Error: POSIX shell (sh or bash) not found."
        exit 1
    }
}

# Invoke the shell script
Push-Location $BaseDir
try {
    & $Shell "scripts/archive-changelog.sh"
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
