# scripts/gen-full-manifest.ps1 - PowerShell wrapper for scripts/gen-full-manifest.sh
#
# Purpose:
#   Programmatically generates a comprehensive mise.toml containing all
#   Tier 1 (Core) and Tier 2 (On-demand) tools.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "gen-full-manifest.sh" $args
