# scripts/docs.ps1 - PowerShell wrapper for scripts/docs.sh
#
# Purpose:
#   Unified entrance for VitePress development and building.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (Idempotency), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "docs.sh" $args
