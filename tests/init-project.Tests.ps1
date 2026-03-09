Describe "Init-Project PowerShell Wrapper" {
    BeforeAll {
        $BaseTemp = [System.IO.Path]::GetTempPath()
        $global:TempPath = Join-Path $BaseTemp ([Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $global:TempPath -Force | Out-Null

        # Create dummy project structure
        New-Item -ItemType File -Path (Join-Path $global:TempPath "LICENSE") -Value "Copyright template" | Out-Null
        New-Item -ItemType File -Path (Join-Path $global:TempPath "README.md") -Value "This is template" | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $global:TempPath ".git") | Out-Null

        # Copy scripts
        $DestScripts = New-Item -ItemType Directory -Path (Join-Path $global:TempPath "scripts")
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\init-project.sh") -Destination $DestScripts
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\init-project.ps1") -Destination $DestScripts
        $DestLib = New-Item -ItemType Directory -Path (Join-Path $global:TempPath "scripts\lib")
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\lib\common.sh") -Destination $DestLib
        Copy-Item -Path (Join-Path $PSScriptRoot "..\scripts\lib\common.ps1") -Destination $DestLib
    }

    AfterAll {
        if (Test-Path $global:TempPath) { Remove-Item -Path $global:TempPath -Recurse -Force }
    }

    It "Should invoke the underlying POSIX shell script if 'sh' is available" {
        $OldCwd = Get-Location
        Set-Location $global:TempPath
        try {
            $ScriptPath = "./scripts/init-project.ps1"
            # We simulate user input causing the underlying script to abort to prove it was called.
            $output = "n`n" | & pwsh -NoProfile -Command "$ScriptPath --project=dummy-app --author='Jane Doe' --github=janeorg" 2>&1

            # Check if the output contains the start of the hydration script
            $outputString = $output -join "`n"
            $outputString -match "Project Hydration" | Should -Be $true
        }
        finally {
            Set-Location $OldCwd
        }
    }
}
