@echo off
setlocal enabledelayedexpansion
title downterm v2.0
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

mode con: cols=60 lines=22

:start
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.0%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%a quiet wrapper around yt-dlp.%R%
echo.
echo   %FAINT%? help   t test   q quit%R%
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
if /i "!url!"=="t" goto selftest
if /i "!url!"=="test" goto selftest
if /i "!url!"=="q" exit /b 0
if /i "!url!"=="quit" exit /b 0
if /i "!url!"=="exit" exit /b 0

rem --- detect batch mode (input is an existing file) ---
if exist "!url!" (
  set "BATCHFILE=!url!"
  goto batchmode
)

rem --- single download: ask type + quality ---
call :asktype
call :askquality

cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.0%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%acquiring%R%  %FAINT%!url!%R%
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

set "FFARG="
if exist "ffmpeg.exe" set "FFARG=.\ffmpeg.exe"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!url!" "%FFARG%" "!MODE!" "!QUALITY!"
set "ec=!errorlevel!"
echo.
echo   %HAIR%-----------------------------------------------%R%
if !ec! equ 10019 (
  echo   %FAINT%  skipped (already downloaded)%R%
) else if !ec! gtr 0 (
  echo   %WARN%finished with warnings.%R%  %FAINT%see error code above%R%
) else (
  echo   %GOOD%saved.%R%  %FAINT%next to yt-dlp.exe%R%
)
echo.
echo   %FAINT%any key to run again.%R%
pause>nul
goto start

:asktype
echo.
set /p "MODE=  %MUT%video or audio? (v/a) [%INK%v%MUT%]%R% "
if /i "!MODE!"=="a" set "MODE=audio" & goto :eof
set "MODE=video"
goto :eof

:askquality
if /i "!MODE!"=="audio" set "QUALITY=best" & goto :eof
echo.
set /p "QUALITY=  %MUT%quality? (b/1/7/4) [%ink%b%MUT%]%R% "
if /i "!QUALITY!"=="1" set "QUALITY=1080" & goto :eof
if /i "!QUALITY!"=="7" set "QUALITY=720" & goto :eof
if /i "!QUALITY!"=="4" set "QUALITY=480" & goto :eof
set "QUALITY=best"
goto :eof

:batchmode
echo.
echo   %MUT%batch file detected.%R%  %FAINT%!BATCHFILE!%R%
call :asktype
call :askquality

rem --- count URLs in file (non-blank, non-#) ---
set "URLCOUNT=0"
for /f "usebackq eol=# tokens=*" %%a in ("!BATCHFILE!") do set /a URLCOUNT+=1

if !URLCOUNT! lss 1 (
  echo   %BAD%no URLs found in !BATCHFILE!%R%
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)

set "FFARG="
if exist "ffmpeg.exe" set "FFARG=.\ffmpeg.exe"

set "CURRENT=0"
for /f "usebackq eol=# tokens=*" %%a in ("!BATCHFILE!") do (
  set /a CURRENT+=1
  set "BATCHURL=%%a"
  call :batchdownload
)

echo.
echo   %HAIR%-----------------------------------------------%R%
echo   %GOOD%  !URLCOUNT! done.%R%
echo.
echo   %FAINT%  any key to run again.%R%
pause>nul
goto start

:batchdownload
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.0%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%[!CURRENT!/!URLCOUNT!]%R%  %FAINT%!BATCHURL!%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!BATCHURL!" "%FFARG%" "!MODE!" "!QUALITY!"
set "ec=!errorlevel!"
echo.
if !ec! equ 10019 (
  echo   %FAINT%  skipped (already downloaded)%R%
) else if !ec! equ 0 (
  echo   %GOOD%  saved.%R%
) else (
  echo   %WARN%  finished with warnings.%R%  %FAINT%see error code above%R%
)
echo.
goto :eof

:selftest
cls
echo.
echo   %ACC%downterm%R%  %FAINT%self-test%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%downloading test video...%R%
echo   %FAINT%https://www.youtube.com/watch?v=Rfyr7-dQnAg%R%
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

set "FFARG="
if exist "ffmpeg.exe" set "FFARG=.\ffmpeg.exe"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "https://www.youtube.com/watch?v=Rfyr7-dQnAg" "%FFARG%" "video" "best"
set "ec=!errorlevel!"
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.

if !ec! gtr 0 (
  echo   %BAD%test failed.%R%  %FAINT%check above for errors%R%
  echo.
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)

echo   %GOOD%downloaded ok.%R%  %MUT%cleaning up...%R%
echo.

set "cleaned=0"
for %%x in (*.mp4 *.mkv *.webm *.mp3 *.m4a) do (
  if exist "%%x" (
    del /q "%%x" 2>nul
    set "cleaned=1"
  )
)
if "!cleaned!"=="1" (
  echo   %GOOD%test file removed.%R%
) else (
  echo   %FAINT%no downloaded file found to delete.%R%
)

echo.
echo   %FAINT%setup is working. press any key to go back.%R%
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
echo     %INK%<%R%  %FAINT%urls.txt  (batch mode)%R%
echo.
echo   %MUT%prompts%R%
echo     %INK%v/a%R%   %FAINT%video or audio (default: video)%R%
echo     %INK%b/1/7/4%R%  %FAINT%best/1080p/720p/480p (default: best)%R%
echo.
echo   %MUT%commands%R%
echo     %INK%?%R%   %FAINT%this screen%R%
echo     %INK%t%R%   %FAINT%self-test (download a sample, then delete)%R%
echo     %INK%q%R%   %FAINT%quit%R%
echo.
echo   %MUT%requires%R%
echo     %FAINT%- yt-dlp.exe in this folder%R%
echo     %FAINT%- ffmpeg.exe (for merging)%R%
echo     %FAINT%- deno.exe (for full youtube formats)%R%
echo     %FAINT%- PowerShell (for progress bar)%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.
echo   %FAINT%any key to go back.%R%
pause>nul
goto start
