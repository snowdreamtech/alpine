@echo off
REM scripts/commit.bat - Windows wrapper for scripts/commit.sh
REM
REM Purpose:
REM   Facilitates high-quality, conventional commits with Commitizen.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0commit.ps1" %*
exit /b %ERRORLEVEL%
