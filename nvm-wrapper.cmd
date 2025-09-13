@echo off
REM nvm.cmd - Wrapper para nvm.ps1
powershell -ExecutionPolicy Bypass -File "%~dp0nvm.ps1" %*