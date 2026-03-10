@echo off
REM scripts/audit.bat - Windows wrapper for scripts/audit.sh
REM
REM Purpose:
REM   Standardizes execution of dependency scans and secret detection modules.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0audit.ps1" %*
exit /b %ERRORLEVEL%
