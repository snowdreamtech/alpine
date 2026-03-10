@echo off
REM scripts/check-env.bat - Windows wrapper for scripts/check-env.sh
REM
REM Purpose:
REM   Validates the developer workstation against project-required runtimes.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (Idempotency), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-env.ps1" %*
exit /b %ERRORLEVEL%
