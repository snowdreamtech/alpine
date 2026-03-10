# scripts/init-project.ps1 - PowerShell wrapper for scripts/init-project.sh
#
# Purpose:
#   Customizes the template for a new project by replacing placeholders.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "init-project.sh" $args
