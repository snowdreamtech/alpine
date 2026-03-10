@echo off
REM scripts/archive-changelog.bat - Windows wrapper for scripts/archive-changelog.sh
REM
REM Purpose:
REM   Moves entries of previous major versions from CHANGELOG.md to archival files.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0archive-changelog.ps1" %*
exit /b %ERRORLEVEL%
