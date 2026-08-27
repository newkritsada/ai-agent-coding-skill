@echo off
rem Windows entry point -- runs sync-skills.ps1 (no Git Bash required).
rem Usage:  sync-skills.cmd  [--dry-run]

setlocal

set "ARGS="
if /i "%~1"=="--dry-run" set "ARGS=-DryRun"
if /i "%~1"=="-n"        set "ARGS=-DryRun"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-skills.ps1" %ARGS%
exit /b %ERRORLEVEL%
