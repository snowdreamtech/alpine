@echo off
REM scripts/test.bat - Windows wrapper for scripts/test.sh
REM
REM Purpose:
REM   Orchestrates multi-stack test suites for holistic verification.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (Idempotency), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1" %*
exit /b %ERRORLEVEL%
