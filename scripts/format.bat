@echo off
REM scripts/format.bat - Windows wrapper for scripts/format.sh
REM
REM Purpose:
REM   Optimizes code style across all project components using uniform rules.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (Idempotency), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0format.ps1" %*
exit /b %ERRORLEVEL%
