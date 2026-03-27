:: scripts/verify.bat - Windows wrapper for scripts/verify.sh
::
:: Purpose:
::   Executes the full project verification suite on Windows.
::   Delegates to POSIX shell to maintain Single Source of Truth (SSoT).
::
:: Standards:
::   - POSIX Shell delegation via sh/bash.
::   - Rule 01 (General), Rule 03 (Architecture).
@echo off
setlocal
set SCRIPT_PATH=%~dp0verify.sh
sh "%SCRIPT_PATH%" %*
exit /b %ERRORLEVEL%
