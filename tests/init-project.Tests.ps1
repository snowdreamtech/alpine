Describe "Init-Project PowerShell Wrapper" {
    It "Should invoke the underlying POSIX shell script if 'sh' is available" {
        $ScriptPath = Join-Path $PSScriptRoot "..\scripts\init-project.ps1"
        # 'sh' is expected to be available in the test environment (macOS/Linux/WSL/Git Bash).
        # We simulate user input causing the underlying script to abort to prove it was called.
        $output = "n`n" | & pwsh -NoProfile -Command "$ScriptPath --project=dummy-app --author='Jane Doe' --github=janeorg" 2>&1

        # Check if the output contains the start of the hydration script
        $outputString = $output -join "`n"
        $outputString -match "Project Hydration" | Should -Be $true
    }
}
