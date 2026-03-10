@echo off
REM scripts/cleanup.bat - Windows wrapper for scripts/cleanup.sh
REM
REM Purpose:
REM   Thoroughly removes build artifacts, temporary files, and caches.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cleanup.ps1" %*
exit /b %ERRORLEVEL%
