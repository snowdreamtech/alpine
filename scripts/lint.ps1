# scripts/lint.ps1 - PowerShell wrapper for scripts/lint.sh
#
# Purpose:
#   Orchestrates code quality checks across all project stacks.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "lint.sh" $args
