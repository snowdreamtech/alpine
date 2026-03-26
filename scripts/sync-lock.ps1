# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/sync-lock.ps1  Mise Lockfile Synchronizer (Windows)
#
# Purpose:
#   Synchronizes mise.lock with the comprehensive manifest (Tier 1 + Tier 2).
#   Ensures all tools are cryptographically locked for all supported platforms.

$ErrorActionPreference = "Stop"

# 1. Housekeeping
$ProjectRoot = Get-Item -Path ".."
Set-Location -Path $ProjectRoot.FullName

# Ensure mise is available
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    Write-Error "Error: mise not found in PATH."
}

Write-Output "Synchronizing mise.lock for all platforms..."

# 2. Manifest Aggregation
$TmpManifest = ".mise.toml.lock.temp"
& ./scripts/gen-full-manifest.bat | Out-File -FilePath $TmpManifest -Encoding utf8

# 3. List Extraction
# We parse the temporary manifest for tool names
$Tools = Get-Content $TmpManifest | Where-Object { $_ -match "=" } | ForEach-Object {
    $parts = $_ -split "="
    $name = $parts[0].Trim().Trim('"')
    return $name
}
$ToolList = $Tools -join " "

# 4. Multi-Platform Locking
# We point mise to the temporary manifest.
$env:MISE_CONFIG = $TmpManifest
& mise lock --platform linux-x64,linux-arm64,macos-x64,macos-arm64,windows-x64 $ToolList

# 5. Cleanup
Remove-Item -Path $TmpManifest -Force

Write-Output "mise.lock synchronized successfully for all platforms."
