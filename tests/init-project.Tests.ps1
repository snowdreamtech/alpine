Describe "Init-Project PowerShell Wrapper" {
    $ScriptPath = Join-Path $PSScriptRoot "..\scripts\init-project.ps1"


    It "Should invoke the underlying POSIX shell script if 'sh' is available" {
        # 'sh' is expected to be available in the test environment (macOS/Linux/WSL/Git Bash).
        # We simulate user input causing the underlying script to abort to prove it was called.
        $output = "dummy`ndummy`ndummy`nn`n" | & pwsh -NoProfile -Command $ScriptPath 2>&1

        # Depending on how pwsh pipes input, we just check if it outputs the initial prompt
        # or the aborted message from the underlying shell script.
        ($output -join "`n") -match "Project Hydration" | Should -Be $true
    }
}
