@echo off
REM scripts/generate-tool-docs.bat - CMD wrapper for generate-tool-docs.sh

setlocal

set "SCRIPT_DIR=%~dp0"
set "SH_SCRIPT=%SCRIPT_DIR%generate-tool-docs.sh"

if not exist "%SH_SCRIPT%" (
    echo Error: Shell script not found: %SH_SCRIPT%
    exit /b 1
)

bash "%SH_SCRIPT%" %*
exit /b %ERRORLEVEL%
