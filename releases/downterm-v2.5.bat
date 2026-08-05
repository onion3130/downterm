@echo off
setlocal enabledelayedexpansion
title downterm
cd /d "%~dp0"
rem downterm v2.5 — number menu only (no URL typing). Archived release.

if /i "%~1"=="--version" (echo downterm v2.5 & exit /b 0)
if /i "%~1"=="--setup" goto setup

goto main

:main
for /F %%? in ('echo prompt $E^|cmd') do set "ESC=%%?"
if not defined ESC set "ESC="
set "R=%ESC%[0m"
set "MUT=%ESC%[38;2;130;140;155m"
set "FAINT=%ESC%[38;2;85;92;105m"
set "HAIR=%ESC%[38;2;45;50;60m"
set "GOOD=%ESC%[38;2;141;198;156m"
set "BAD=%ESC%[38;2;230;120;140m"
set "INK=%ESC%[38;2;235;240;248m"
set "ACC=%ESC%[38;2;160;190;235m"
set "WARN=%ESC%[38;2;225;180;120m"
mode con: cols=56 lines=22
set "MODE=video"
set "QUALITY=best"
set "SUBS=0"
set "FORCE=0"
set "SPONSOR=0"
set "ARG_OUTPUT="

:menu
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.5%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%no typing. pick a number.%R%
echo.
echo   %INK%1%R%  %FAINT%paste link  ·  download best video%R%
echo   %INK%2%R%  %FAINT%paste link  ·  pick quality%R%
echo   %INK%3%R%  %FAINT%paste link  ·  audio only%R%
echo   %INK%4%R%  %FAINT%history%R%
echo   %INK%5%R%  %FAINT%open folder%R%
echo   %INK%6%R%  %FAINT%setup tools%R%
echo   %INK%7%R%  %FAINT%help%R%
echo   %INK%8%R%  %FAINT%quit%R%
echo.
choice /c 12345678 /n /m "  %MUT%>%R% "
set "C=!errorlevel!"
if "!C!"=="1" goto quick_video
if "!C!"=="2" goto pick_video
if "!C!"=="3" goto quick_audio
if "!C!"=="4" goto history
if "!C!"=="5" goto openfolder
if "!C!"=="6" goto setup
if "!C!"=="7" goto help
if "!C!"=="8" exit /b 0
goto menu

:getclip
set "url="
for /f "usebackq delims=" %%c in (`powershell -NoProfile -Command "try { $t=(Get-Clipboard -Raw); if ($t -match 'https?://\S+') { $matches[0].TrimEnd([char]41,[char]46,[char]44,[char]34) } } catch { '' }"`) do set "url=%%c"
if "!url!"=="" (
  echo.
  echo   %BAD%no link in clipboard.%R%
  echo   %FAINT%copy a video link, then try again.%R%
  pause>nul
  exit /b 1
)
echo.
echo   %MUT%link%R%  %FAINT%!url!%R%
exit /b 0

:quick_video
call :getclip
if errorlevel 1 goto menu
set "MODE=video" & set "QUALITY=best" & set "SUBS=0" & set "FORCE=0" & set "SPONSOR=0"
goto rundl

:quick_audio
call :getclip
if errorlevel 1 goto menu
set "MODE=audio" & set "QUALITY=best" & set "SUBS=0" & set "FORCE=0" & set "SPONSOR=0"
goto rundl

:pick_video
call :getclip
if errorlevel 1 goto menu
cls
echo.
echo   %ACC%quality%R%
echo.
echo   %INK%1%R% best  %INK%2%R% 1080  %INK%3%R% 720  %INK%4%R% 480  %INK%5%R% 1440  %INK%6%R% 4K  %INK%7%R% back
echo.
choice /c 1234567 /n /m "  %MUT%>%R% "
set "Q=!errorlevel!"
if "!Q!"=="7" goto menu
if "!Q!"=="1" set "QUALITY=best"
if "!Q!"=="2" set "QUALITY=1080"
if "!Q!"=="3" set "QUALITY=720"
if "!Q!"=="4" set "QUALITY=480"
if "!Q!"=="5" set "QUALITY=1440"
if "!Q!"=="6" set "QUALITY=2160"
set "MODE=video" & set "SUBS=0" & set "FORCE=0" & set "SPONSOR=0"
echo.
echo   %INK%1%R% download  %INK%2%R% +subs  %INK%3%R% +sponsor  %INK%4%R% both
choice /c 1234 /n /m "  %MUT%>%R% "
set "E=!errorlevel!"
if "!E!"=="2" set "SUBS=1"
if "!E!"=="3" set "SPONSOR=1"
if "!E!"=="4" set "SUBS=1" & set "SPONSOR=1"
goto rundl

:rundl
> "%~dp0.downterm_last.txt" echo !url!
echo !url!>> "%~dp0.downterm_history"
cls
echo.
echo   %ACC%downterm%R%
echo   %MUT%downloading%R%  %FAINT%!url!%R%
echo.
if not exist "yt-dlp.exe" (echo   %BAD%yt-dlp missing — setup first%R% & pause>nul & goto menu)
set "FFARG="
if exist "ffmpeg.exe" set "FFARG=.\ffmpeg.exe"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!url!" "%FFARG%" "!MODE!" "!QUALITY!" "!ARG_OUTPUT!" "!SUBS!" "!FORCE!" "!SPONSOR!"
set "ec=!errorlevel!"
if !ec! gtr 0 (echo   %WARN%not saved cleanly.%R%) else (echo   %GOOD%saved.%R%)
pause>nul
goto menu

:history
cls
echo   %ACC%history%R%
if not exist "%~dp0.downterm_history" (echo empty & pause>nul & goto menu)
set "HCOUNT=0"
for /f "usebackq delims=" %%h in ("%~dp0.downterm_history") do (set /a HCOUNT+=1 & set "H!HCOUNT!=%%h")
if !HCOUNT! lss 1 (echo empty & pause>nul & goto menu)
set "SHOWFROM=1"
if !HCOUNT! gtr 9 set /a SHOWFROM=HCOUNT-8
set "N=0"
for /l %%i in (!SHOWFROM!,1,!HCOUNT!) do (set /a N+=1 & call set "HLINE=%%H%%i%%" & echo   !N!  !HLINE!)
echo   0  back
choice /c 1234567890 /n /m "  > "
set "HP=!errorlevel!"
if "!HP!"=="10" goto menu
if !HP! gtr !N! goto menu
set /a IDX=SHOWFROM+HP-1
call set "url=%%H!IDX!%%"
set "MODE=video" & set "QUALITY=best" & set "SUBS=0" & set "FORCE=0" & set "SPONSOR=0"
goto rundl

:openfolder
start "" explorer "%~dp0"
goto menu

:help
cls
echo   %ACC%help v2.5%R%
echo.
echo   Copy a link in your browser.
echo   Press 1 here for best video.
echo   Press 2 to pick quality with numbers.
echo.
pause>nul
goto menu

:setup
cls
echo   %ACC%setup%R%
if not exist "%~dp0bin\checksums.txt" (echo missing checksums & pause>nul & goto menu)
set "YTURL=" & set "YTHASH="
for /f "usebackq tokens=1,2,3,4 eol=#" %%a in ("%~dp0bin\checksums.txt") do (
  if /i "%%a"=="yt-dlp_windows" (set "YTURL=%%d" & set "YTHASH=%%c")
)
where curl.exe >nul 2>&1 || (echo curl missing & pause>nul & goto menu)
if not exist "yt-dlp.exe" if defined YTURL (
  curl -L --max-time 180 -o "yt-dlp.exe.tmp" "%YTURL%" 2>nul
  call :verifyhash "yt-dlp.exe.tmp" "%YTHASH%" "yt-dlp.exe"
)
echo   %GOOD%done.%R%
pause>nul
goto menu

:verifyhash
set "TMPF=%~1" & set "EXPECTED=%~2" & set "FINAL=%~3"
if not exist "%TMPF%" exit /b 1
set "ACTUAL="
for /f "skip=1 tokens=* delims=" %%i in ('certutil -hashfile "%TMPF%" SHA256 2^>nul') do if not defined ACTUAL set "ACTUAL=%%i"
set "ACTUAL=%ACTUAL: =%" & set "ACTUAL=%ACTUAL:~0,64%"
if /i not "!ACTUAL!"=="%EXPECTED%" (del /q "%TMPF%" 2>nul & exit /b 1)
move /y "%TMPF%" "%FINAL%" >nul
exit /b 0
