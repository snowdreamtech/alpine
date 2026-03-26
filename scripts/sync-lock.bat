@echo off
REM scripts/sync-lock.bat - Windows wrapper for scripts/sync-lock.ps1
REM
REM Purpose:
REM   Synchronizes and verifies the mise.lock file across all platforms.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-lock.ps1" %*
exit /b %ERRORLEVEL%
