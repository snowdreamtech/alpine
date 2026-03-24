# scripts/gen-dependabot.ps1 - PowerShell wrapper for scripts/gen-dependabot.sh
#
# Purpose:
#   Scans the repository for manifest files and generates a minimal dependabot.yml.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "gen-dependabot.sh" $args
