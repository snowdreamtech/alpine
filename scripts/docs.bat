@echo off
REM scripts/docs.bat - Windows wrapper for scripts/docs.sh
REM
REM Purpose:
REM   Unified entrance for VitePress development and building.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0docs.ps1" %*
exit /b %ERRORLEVEL%
