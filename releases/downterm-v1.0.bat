@echo off
setlocal enabledelayedexpansion
title downterm v1.0
cd /d "%~dp0"

rem ===== ANSI color codes =====
for /F %%? in ('echo prompt $E^|cmd') do set "ESC=%%?"
set "R=%ESC%[0m"
set "B=%ESC%[1m"
set "D=%ESC%[2m"
set "SOFT=%ESC%[38;2;168;181;203m"
set "MUT=%ESC%[38;2;110;120;135m"
set "FAINT=%ESC%[38;2;75;82;94m"
set "GOOD=%ESC%[38;2;141;198;156m"
set "BAD=%ESC%[38;2;220;130;120m"
set "INK=%ESC%[38;2;226;232;240m"

mode con: cols=56 lines=14

:start
cls
echo.
echo.
echo   %D%.  .  .  .  .  .  .  .  .  .  .  .  .%R%
echo   %MUT%  d  o  w  n%R%  %FAINT%/  %MUT%y  t  -  d  l  p%R%
echo   %D%.  .  .  .  .  .  .  .  .  .  .  .  .%R%
echo.
echo   %FAINT%................................................%R%
echo.
set /p "url=   %INK%^>%R% "
if "!url!"=="" goto start
echo   %FAINT%................................................%R%
echo.
yt-dlp.exe -f "bv*+ba/b" --merge-output-format mp4 -o "%%(title)s.%%(ext)s" --newline "!url!" 2>&1 | findstr /v "^$"
echo.
echo   %FAINT%................................................%R%
echo   %GOOD%  ok%R%
echo.
echo   %FAINT%  any key%R%
pause>nul
goto start
