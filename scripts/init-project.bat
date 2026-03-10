@echo off
REM scripts/init-project.bat - Windows wrapper for scripts/init-project.sh
REM
REM Purpose:
REM   Customizes the template for a new project by replacing placeholders.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (Idempotency), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init-project.ps1" %*
exit /b %ERRORLEVEL%
