@echo off
setlocal enabledelayedexpansion
title downterm v1.2
cd /d "%~dp0"

for /F %%? in ('echo prompt $E^|cmd') do set "ESC=%%?"
set "R=%ESC%[0m"
set "B=%ESC%[1m"
set "D=%ESC%[2m"
set "SOFT=%ESC%[38;2;200;210;225m"
set "MUT=%ESC%[38;2;130;140;155m"
set "FAINT=%ESC%[38;2;85;92;105m"
set "HAIR=%ESC%[38;2;45;50;60m"
set "GOOD=%ESC%[38;2;141;198;156m"
set "BAD=%ESC%[38;2;230;120;120m"
set "INK=%ESC%[38;2;235;240;248m"
set "ACC=%ESC%[38;2;160;190;235m"

mode con: cols=60 lines=20

:start
cls
echo.
echo       %ACC%  downterm%R%  %FAINT%v1.2%R%
echo       %HAIR%  ...............................................%R%
echo.
echo       %MUT%  a quiet wrapper around yt-dlp.%R%
echo.
echo       %HAIR%  +---------------------------------------------+%R%
echo       %HAIR%  ^| %FAINT%paste a url, press enter.                %HAIR%^|%R%
echo       %HAIR%  ^| %FAINT%best av, merged to mp4.                 %HAIR%^|%R%
echo       %HAIR%  +---------------------------------------------+%R%
echo.
set /p "url=  %B%%INK%^>%R% "
if "!url!"=="" (
  echo       %BAD%  nothing entered.%R%
  echo       %FAINT%  press any key...%R%
  pause>nul
  goto start
)
echo       %HAIR%  +---------------------------------------------+%R%
echo.
echo       %MUT%  acquiring%R%  %FAINT%!url!%R%
echo.
yt-dlp.exe -f "bv*+ba/b" --merge-output-format mp4 -o "%%(title)s.%%(ext)s" --newline "!url!" 2>&1 | findstr /v "^$"
echo.
echo       %HAIR%  +---------------------------------------------+%R%
echo.
echo       %GOOD%  saved.%R%  %FAINT%next to yt-dlp.exe%R%
echo.
echo       %FAINT%  any key to run again.%R%
pause>nul
goto start
