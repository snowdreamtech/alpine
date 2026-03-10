@echo off
REM scripts/lint.bat - Windows wrapper for scripts/lint.sh
REM
REM Purpose:
REM   Orchestrates code quality checks across all project stacks.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lint.ps1" %*
exit /b %ERRORLEVEL%
