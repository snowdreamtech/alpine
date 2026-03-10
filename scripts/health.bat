@echo off
REM scripts/health.bat - Windows wrapper for scripts/health.sh
REM
REM Purpose:
REM   Consolidates environment checks, linting, testing, and security auditing.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0health.ps1" %*
exit /b %ERRORLEVEL%
