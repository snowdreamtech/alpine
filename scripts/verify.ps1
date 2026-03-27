# scripts/verify.ps1 - PowerShell wrapper for scripts/verify.sh
#
# Purpose:
#   Executes the full project verification suite on Windows.
#   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
#
# Standards:
#   - POSIX Shell delegation (sh/bash detection).
#   - Rule 01 (General), Rule 03 (Architecture).

. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "verify.sh" $args
