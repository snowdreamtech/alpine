@echo off
REM scripts/build.bat - Windows wrapper for scripts/build.sh
REM
REM Purpose:
REM   Orchestrates multi-stack build systems into a single CLI.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (Idempotency), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
exit /b %ERRORLEVEL%
