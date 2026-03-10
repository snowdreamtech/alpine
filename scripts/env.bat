@echo off
REM scripts/env.bat - Windows wrapper for scripts/env.sh
REM
REM Purpose:
REM   Standardizes management of .env files and template synchronization.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0env.ps1" %*
exit /b %ERRORLEVEL%
