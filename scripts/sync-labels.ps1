# sync-labels.ps1
# Purpose: Synchronizes and brands repository labels using GitHub CLI (gh) on Windows.
# Design: Ensures consistent colors and descriptions for engineering labels.

$ErrorActionPreference = "Stop"

# Define SnowdreamTech Brand Colors & Labels
$Labels = @(
    @{ Name = "dependencies"; Color = "0366d6"; Description = "Dependencies and package updates" }
    @{ Name = "devops"; Color = "7d31b2"; Description = "CI/CD, infrastructure and dev environment" }
    @{ Name = "infrastructure"; Color = "6b5aed"; Description = "Core infrastructure, Docker, and system configs" }
    @{ Name = "linting"; Color = "ffcc00"; Description = "Code style, linting, and formatting" }
    @{ Name = "javascript"; Color = "f7df1e"; Description = "JavaScript/TypeScript ecosystem" }
    @{ Name = "github-actions"; Color = "2088ff"; Description = "GitHub Actions workflow changes" }
)

function Sync-Label {
    param (
        [string]$Name,
        [string]$Color,
        [string]$Description
    )

    Write-Output "Syncing label: $Name (color: #$Color)"

    $ExistingLabels = gh label list --json name | ConvertFrom-Json
    $Exists = $ExistingLabels | Where-Object { $_.name -eq $Name }

    if ($Exists) {
        gh label edit $Name --color $Color --description $Description
    } else {
        gh label create $Name --color $Color --description $Description
    }
}

# Main loop
foreach ($Label in $Labels) {
    Sync-Label -Name $Label.Name -Color $Label.Color -Description $Label.Description
}

Write-Output "All labels synchronized successfully."
