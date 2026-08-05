@echo off
setlocal
cd /d "%~dp0"
title downterm setup
echo.
echo   downterm setup
echo   ..........................................
echo.
rem Forward flags to setup.ps1: -PathOnly  -SkipPath  -ForceTools
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
set "EC=%ERRORLEVEL%"
echo.
if not "%EC%"=="0" (
  echo   setup finished with errors.
) else (
  echo   close this window, open a NEW terminal, type:  downterm
)
echo.
pause
exit /b %EC%
