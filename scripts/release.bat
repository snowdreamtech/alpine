@echo off
REM scripts/release.bat - Windows wrapper for scripts/release.sh
REM
REM Purpose:
REM   Automates semantic versioning, git tagging, and pre-release verification.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0release.ps1" %*
exit /b %ERRORLEVEL%
