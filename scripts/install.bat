@echo off
REM scripts/install.bat - Windows wrapper for scripts/install.sh
REM
REM Purpose:
REM   Orchestrates project dependency installation across package managers.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (Idempotency), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
exit /b %ERRORLEVEL%
