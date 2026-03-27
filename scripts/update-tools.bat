@echo off
REM scripts/update-tools.bat - Windows wrapper for scripts/update-tools.sh
REM
REM Purpose:
REM   Intelligent tool version upgrader for Mise.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-tools.ps1" %*
exit /b %ERRORLEVEL%
