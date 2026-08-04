@echo off
setlocal enabledelayedexpansion
title downterm v1.7
cd /d "%~dp0"

for /F %%? in ('echo prompt $E^|cmd') do set "ESC=%%?"
if not defined ESC set "ESC="

set "R=%ESC%[0m"
set "B=%ESC%[1m"
set "D=%ESC%[2m"
set "MUT=%ESC%[38;2;130;140;155m"
set "FAINT=%ESC%[38;2;85;92;105m"
set "HAIR=%ESC%[38;2;45;50;60m"
set "GOOD=%ESC%[38;2;141;198;156m"
set "BAD=%ESC%[38;2;230;120;140m"
set "INK=%ESC%[38;2;235;240;248m"
set "ACC=%ESC%[38;2;160;190;235m"
set "WARN=%ESC%[38;2;225;180;120m"

mode con: cols=60 lines=20

:start
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v1.7%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%a quiet wrapper around yt-dlp.%R%
echo.
echo   %FAINT%? help   q quit%R%
echo.
set /p "url=  %INK%<%R% "
if "!url!"=="" (
  echo.
  echo   %BAD%nothing entered.%R%
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)

if /i "!url!"=="?" goto help
if /i "!url!"=="help" goto help
if /i "!url!"=="q" exit /b 0
if /i "!url!"=="quit" exit /b 0
if /i "!url!"=="exit" exit /b 0

:download
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v1.7%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%acquiring%R%
echo   %FAINT%!url!%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.

if not exist "yt-dlp.exe" (
  echo   %BAD%yt-dlp.exe not found.%R%
  echo   %FAINT%get it: github.com/yt-dlp/yt-dlp%R%
  echo.
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)

yt-dlp.exe -f "bv*+ba/b" --merge-output-format mp4 -o "%%(title)s.%%(ext)s" --newline "!url!" 2>&1 | findstr /v "^$"

echo.
echo   %HAIR%-----------------------------------------------%R%
if errorlevel 1 (
  echo   %WARN%finished with warnings.%R%  %FAINT%check above%R%
) else (
  echo   %GOOD%saved.%R%  %FAINT%next to yt-dlp.exe%R%
)
echo.
echo   %FAINT%any key to run again.%R%
pause>nul
goto start

:help
cls
echo.
echo   %ACC%downterm%R%  %FAINT%help%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%usage%R%
echo     %INK%<%R%  %FAINT%url, then enter%R%
echo.
echo   %MUT%commands%R%
echo     %INK%?%R%   %FAINT%this screen%R%
echo     %INK%q%R%   %FAINT%quit%R%
echo.
echo   %MUT%requires%R%
echo     %FAINT%- yt-dlp.exe in this folder%R%
echo     %FAINT%- ffmpeg.exe (for merging)%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.
echo   %FAINT%any key to go back.%R%
pause>nul
goto start
