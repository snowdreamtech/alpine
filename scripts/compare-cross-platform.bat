@echo off
REM scripts/compare-cross-platform.bat - CMD wrapper for compare-cross-platform.sh

setlocal

set "SCRIPT_DIR=%~dp0"
set "SH_SCRIPT=%SCRIPT_DIR%compare-cross-platform.sh"

if not exist "%SH_SCRIPT%" (
    echo Error: Shell script not found: %SH_SCRIPT%
    exit /b 1
)

bash "%SH_SCRIPT%" %*
exit /b %ERRORLEVEL%
