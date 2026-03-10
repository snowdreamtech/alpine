Describe "Init-Project PowerShell Wrapper" {
    $script:TestTempPath = $null

    BeforeAll {
        $BaseTemp = [System.IO.Path]::GetTempPath()
        $script:TestTempPath = Join-Path $BaseTemp ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $script:TestTempPath -Force | Out-Null

        # Create dummy project structure
        New-Item -ItemType File -Path (Join-Path $script:TestTempPath "LICENSE") -Value "Copyright template" | Out-Null
        New-Item -ItemType File -Path (Join-Path $script:TestTempPath "README.md") -Value "This is template" | Out-Null
        New-Item -ItemType File -Path (Join-Path $script:TestTempPath "Makefile") -Value "" | Out-Null
        New-Item -ItemType File -Path (Join-Path $script:TestTempPath "package.json") -Value "{}" | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:TestTempPath ".git") | Out-Null

        # Copy scripts
        $DestScripts = New-Item -ItemType Directory -Path (Join-Path $script:TestTempPath "scripts")
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\init-project.sh") -Destination $DestScripts
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\init-project.ps1") -Destination $DestScripts
        $DestLib = New-Item -ItemType Directory -Path (Join-Path $script:TestTempPath "scripts\lib")
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\lib\common.sh") -Destination $DestLib
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\lib\common.ps1") -Destination $DestLib
    }

    AfterAll {
        if ($script:TestTempPath -and (Test-Path $script:TestTempPath)) { Remove-Item -Path $script:TestTempPath -Recurse -Force }
    }

    It "Should invoke the underlying POSIX shell script if 'sh' is available" {
        $OldCwd = Get-Location
        Set-Location $script:TestTempPath
        try {
            $ScriptPath = "./scripts/init-project.ps1"
            # We simulate user input causing the underlying script to abort to prove it was called.
            $output = "n`n" | & pwsh -NoProfile -Command "$ScriptPath --project=dummy-app --author='Jane Doe' --github=janeorg" 2>&1

            # Check if the output contains the start of the hydration script
            $outputString = $output -join "`n"
            $outputString | Should -Match "Project Hydration"
        }
        finally {
            Set-Location $OldCwd
        }
    }
}
