@echo off
setlocal enabledelayedexpansion
title downterm v1.4
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
set "BAD=%ESC%[38;2;230;120;140m"
set "INK=%ESC%[38;2;235;240;248m"
set "ACC=%ESC%[38;2;160;190;235m"
set "WARN=%ESC%[38;2;225;180;120m"

mode con: cols=60 lines=24

:start
cls
echo.
echo       %ACC%  downterm%R%  %FAINT%v1.4%R%
echo       %HAIR%  ...............................................%R%
echo.
echo       %MUT%  a quiet wrapper around yt-dlp.%R%
echo.
echo       %HAIR%  +---------------------------------------------+%R%
echo       %HAIR%  ^| %FAINT%paste a url, press enter.                %HAIR%^|%R%
echo       %HAIR%  ^| %FAINT%best av, merged to mp4.                 %HAIR%^|%R%
echo       %HAIR%  ^| %FAINT%saved here, next to yt-dlp.exe.        %HAIR%^|%R%
echo       %HAIR%  ^| %FAINT%tip: ^? for help, q to quit.              %HAIR%^|%R%
echo       %HAIR%  +---------------------------------------------+%R%
echo.
set /p "url=  %B%%INK%^>%R% "
if "!url!"=="" (
  echo.
  echo       %BAD%  nothing entered.%R%
  echo       %FAINT%  press any key...%R%
  pause>nul
  goto start
)

rem ---- help ----
if /i "!url!"=="?" goto help
if /i "!url!"=="help" goto help

rem ---- quit ----
if /i "!url!"=="q" exit /b 0
if /i "!url!"=="quit" exit /b 0
if /i "!url!"=="exit" exit /b 0

echo       %HAIR%  +---------------------------------------------+%R%
echo.
echo       %MUT%  acquiring%R%  %FAINT%!url!%R%
echo.

rem ---- check yt-dlp.exe exists ----
if not exist "yt-dlp.exe" (
  echo       %BAD%  yt-dlp.exe not found in this folder.%R%
  echo       %FAINT%  download it from github.com/yt-dlp/yt-dlp%R%
  echo.
  echo       %FAINT%  press any key...%R%
  pause>nul
  goto start
)

yt-dlp.exe -f "bv*+ba/b" --merge-output-format mp4 -o "%%(title)s.%%(ext)s" --newline "!url!" 2>&1 | findstr /v "^$"

if errorlevel 1 (
  echo.
  echo       %HAIR%  +---------------------------------------------+%R%
  echo.
  echo       %WARN%  finished with warnings.%R%  %FAINT%check output above%R%
) else (
  echo.
  echo       %HAIR%  +---------------------------------------------+%R%
  echo.
  echo       %GOOD%  saved.%R%  %FAINT%next to yt-dlp.exe%R%
)
echo.
echo       %FAINT%  any key to run again.%R%
pause>nul
goto start

:help
cls
echo.
echo       %ACC%  downterm%R%  %FAINT%help%R%
echo       %HAIR%  ...............................................%R%
echo.
echo       %MUT%  usage:%R%
echo         %INK%  ^>%R%  %FAINT%paste a url, press enter to download%R%
echo.
echo       %MUT%  commands:%R%
echo         %INK%  ?%R%      %FAINT%this help screen%R%
echo         %ink%  q%R%      %FAINT%quit downterm%R%
echo.
echo       %MUT%  what it does:%R%
echo         %FAINT%  - picks best video + best audio%R%
echo         %FAINT%  - merges them into an mp4%R%
echo         %FAINT%  - saves the file next to yt-dlp.exe%R%
echo.
echo       %HAIR%  -----------------------------------------------%R%
echo.
echo       %FAINT%  any key to go back.%R%
pause>nul
goto start
