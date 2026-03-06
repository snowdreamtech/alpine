# scripts/setup.ps1 - Project Setup Script for Windows (PowerShell)
# This script initializes the development environment by delegating to setup.sh
# using a compatible shell (Git Bash, WSL, MSYS2, or standalone bash).

[CmdletBinding()]
param()

Write-Information "🚀 Initializing Snowdream Tech AI IDE Template for Windows..." -InformationAction Continue
Write-Information "[PS1] Finding a compatible POSIX shell to execute setup.sh..." -InformationAction Continue

$ArgsString = $args -join " "
$SetupScript = Join-Path $PSScriptRoot "setup.sh"
# Normalize path for shell
$SetupScriptPosix = $SetupScript -replace '\\', '/'

# Function to execute and exit
function Invoke-WithShell([string]$ShellPath, [string]$ShellName) {
    Write-Information "[PS1] Using $ShellName at $ShellPath" -InformationAction Continue

    # We use -c to run the script and properly pass arguments
    $Command = "`"$SetupScriptPosix`" $ArgsString"

    # Run the shell, wait for it to exit, and return its exit code
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $ShellPath
    $ProcessInfo.Arguments = "-c `"$Command`""
    $ProcessInfo.UseShellExecute = $false

    $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
    $Process.WaitForExit()

    if ($Process.ExitCode -eq 0) {
        Write-Information "`n✨ Setup completed successfully via $ShellName!" -InformationAction Continue
    }
    else {
        Write-Information "`n❌ Setup failed with exit code $($Process.ExitCode)." -InformationAction Continue
    }

    exit $Process.ExitCode
}

# 1. Try Git Bash (most common for Windows devs)
$GitBash = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $GitBash) {
    Invoke-WithShell $GitBash "Git Bash"
}

# 2. Try looking for bash in PATH
$BashInPath = (Get-Command bash -ErrorAction SilentlyContinue).Source
if ($BashInPath) {
    Invoke-WithShell $BashInPath "bash (from PATH)"
}

# 3. Try looking for sh in PATH
$ShInPath = (Get-Command sh -ErrorAction SilentlyContinue).Source
if ($ShInPath) {
    Invoke-WithShell $ShInPath "sh (from PATH)"
}

# 4. Try WSL (Windows Subsystem for Linux)
$WslPath = "$env:WINDIR\System32\wsl.exe"
if (Test-Path $WslPath) {
    Write-Information "[PS1] Using WSL (Windows Subsystem for Linux)" -InformationAction Continue

    # Convert Windows path to WSL path (e.g., C:\ -> /mnt/c/)
    $Drive = $SetupScript.Substring(0, 1).ToLower()
    $WslScriptPath = "/mnt/$Drive" + ($SetupScript.Substring(2) -replace '\\', '/')
    $WslCommand = "$WslScriptPath $ArgsString"

    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $WslPath
    $ProcessInfo.Arguments = "-l -e sh -c `"$WslCommand`""
    $ProcessInfo.UseShellExecute = $false

    $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
    $Process.WaitForExit()

    if ($Process.ExitCode -eq 0) {
        Write-Information "`n✨ Setup completed successfully via WSL!" -InformationAction Continue
    }
    else {
        Write-Information "`n❌ Setup failed with exit code $($Process.ExitCode)." -InformationAction Continue
    }
    exit $Process.ExitCode
}

Write-Error "❌ Could not find a compatible POSIX shell (Git Bash, MSYS2, WSL, or bash/sh in PATH). Please install Git for Windows or WSL to run this setup."
exit 1
