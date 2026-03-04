@echo off
REM CMD wrapper for init-project.ps1

powershell -ExecutionPolicy Bypass -File "%~dp0init-project.ps1"
