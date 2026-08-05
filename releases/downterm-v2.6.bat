@echo off
setlocal enabledelayedexpansion
title downterm
cd /d "%~dp0"

rem --- v2.6 default: open the click GUI (no typing) ---
rem     --tui     menu terminal
rem     --setup / --version / --gui explicit
rem     any other args: pass through to TUI for rare scripting

if /i "%~1"=="--version" (
  echo downterm v2.6
  exit /b 0
)
if /i "%~1"=="--setup" goto setup
if /i "%~1"=="--tui" goto tui
if /i "%~1"=="--gui" goto gui
if /i "%~1"=="--cli" goto tui
if not "%~1"=="" goto tui

:gui
if not exist "%~dp0gui.ps1" goto tui
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gui.ps1"
if errorlevel 1 goto tui
exit /b 0

:tui
goto main

:die
echo.
echo   press any key...
pause>nul
exit /b 0

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
if exist "%~dp0downterm.conf" (
  for /f "usebackq eol=# tokens=1,2 delims==" %%a in ("%~dp0downterm.conf") do (
    if /i "%%a"=="MODE" set "MODE=%%b"
    if /i "%%a"=="QUALITY" set "QUALITY=%%b"
    if /i "%%a"=="OUTPUT" set "ARG_OUTPUT=%%b"
    if /i "%%a"=="SUBS" set "SUBS=%%b"
    if /i "%%a"=="FORCE" set "FORCE=%%b"
    if /i "%%a"=="SPONSORBLOCK" set "SPONSOR=%%b"
  )
)

:menu
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.6%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%no typing. pick a number.%R%
echo.
echo   %INK%1%R%  %FAINT%paste link  ·  download best video%R%
echo   %INK%2%R%  %FAINT%paste link  ·  pick quality%R%
echo   %INK%3%R%  %FAINT%paste link  ·  audio only%R%
echo   %INK%4%R%  %FAINT%history%R%
echo   %INK%5%R%  %FAINT%open folder%R%
echo   %INK%6%R%  %FAINT%open window gui%R%
echo   %INK%7%R%  %FAINT%setup tools%R%
echo   %INK%8%R%  %FAINT%help%R%
echo   %INK%9%R%  %FAINT%quit%R%
echo.
choice /c 123456789 /n /m "  %MUT%>%R% "
set "C=!errorlevel!"
if "!C!"=="1" goto quick_video
if "!C!"=="2" goto pick_video
if "!C!"=="3" goto quick_audio
if "!C!"=="4" goto history
if "!C!"=="5" goto openfolder
if "!C!"=="6" goto gui
if "!C!"=="7" goto setup
if "!C!"=="8" goto help
if "!C!"=="9" exit /b 0
goto menu

:getclip
set "url="
for /f "usebackq delims=" %%c in (`powershell -NoProfile -Command "try { $t=(Get-Clipboard -Raw); if ($t -match 'https?://\S+') { $matches[0].TrimEnd(').,]>`"''') } } catch { '' }"`) do set "url=%%c"
if "!url!"=="" (
  echo.
  echo   %BAD%no link in clipboard.%R%
  echo   %FAINT%copy a youtube/video link, then try again.%R%
  echo.
  echo   %FAINT%any key...%R%
  pause>nul
  exit /b 1
)
echo.
echo   %MUT%link%R%  %FAINT%!url!%R%
exit /b 0

:quick_video
call :getclip
if errorlevel 1 goto menu
set "MODE=video"
set "QUALITY=best"
set "SUBS=0"
set "FORCE=0"
set "SPONSOR=0"
goto rundl

:quick_audio
call :getclip
if errorlevel 1 goto menu
set "MODE=audio"
set "QUALITY=best"
set "SUBS=0"
set "FORCE=0"
set "SPONSOR=0"
goto rundl

:pick_video
call :getclip
if errorlevel 1 goto menu
cls
echo.
echo   %ACC%quality%R%
echo   %HAIR%..........................................%R%
echo.
echo   %INK%1%R%  best
echo   %INK%2%R%  1080p
echo   %INK%3%R%  720p
echo   %INK%4%R%  480p
echo   %INK%5%R%  1440p
echo   %INK%6%R%  4K
echo   %INK%7%R%  back
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
set "MODE=video"
set "SUBS=0"
set "FORCE=0"
set "SPONSOR=0"
echo.
echo   %FAINT%extras?%R%
echo   %INK%1%R%  download now
echo   %INK%2%R%  + english subs
echo   %INK%3%R%  + sponsorblock
echo   %INK%4%R%  + both
echo.
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
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%downloading%R%
echo   %FAINT%!url!%R%
echo.
echo   %HAIR%------------------------------------------%R%
echo.
if not exist "yt-dlp.exe" (
  echo   %BAD%yt-dlp.exe missing — press 7 for setup%R%
  pause>nul
  goto menu
)
set "FFARG="
if exist "ffmpeg.exe" set "FFARG=.\ffmpeg.exe"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!url!" "%FFARG%" "!MODE!" "!QUALITY!" "!ARG_OUTPUT!" "!SUBS!" "!FORCE!" "!SPONSOR!"
set "ec=!errorlevel!"
echo.
echo   %HAIR%------------------------------------------%R%
if !ec! gtr 0 (
  echo   %WARN%not saved cleanly.%R%
) else (
  echo   %GOOD%saved.%R%
)
echo.
echo   %FAINT%any key...%R%
pause>nul
goto menu

:history
cls
echo.
echo   %ACC%history%R%
echo   %HAIR%..........................................%R%
echo.
if not exist "%~dp0.downterm_history" (
  echo   %FAINT%empty%R%
  pause>nul
  goto menu
)
set "HCOUNT=0"
for /f "usebackq delims=" %%h in ("%~dp0.downterm_history") do (
  set /a HCOUNT+=1
  set "H!HCOUNT!=%%h"
)
if !HCOUNT! lss 1 (
  echo   %FAINT%empty%R%
  pause>nul
  goto menu
)
set "SHOWFROM=1"
if !HCOUNT! gtr 9 set /a SHOWFROM=HCOUNT-8
set "N=0"
for /l %%i in (!SHOWFROM!,1,!HCOUNT!) do (
  set /a N+=1
  call set "HLINE=%%H%%i%%"
  echo   %INK%!N!%R%  !HLINE!
)
echo   %INK%0%R%  back
echo.
choice /c 1234567890 /n /m "  %MUT%>%R% "
set "HP=!errorlevel!"
if "!HP!"=="10" goto menu
if !HP! gtr !N! goto menu
set /a IDX=SHOWFROM+HP-1
call set "url=%%H!IDX!%%"
if "!url!"=="" goto menu
set "MODE=video"
set "QUALITY=best"
set "SUBS=0"
set "FORCE=0"
set "SPONSOR=0"
goto rundl

:openfolder
start "" explorer "%~dp0"
goto menu

:help
cls
echo.
echo   %ACC%help%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%window gui%R%  %FAINT%(default when you double-click)%R%
echo     paste button · pick quality · download
echo.
echo   %MUT%this menu%R%
echo     1  clipboard → best video  (zero choices)
echo     2  clipboard → pick quality
echo     3  clipboard → audio
echo     4  history
echo     5  folder
echo     6  window window
echo     7  fetch yt-dlp / ffmpeg / deno
echo.
echo   %FAINT%copy a link in your browser, then press 1.%R%
echo.
echo   %FAINT%any key...%R%
pause>nul
goto menu

:showversion
echo downterm v2.6
exit /b 0

:setup
cls
echo.
echo   %ACC%setup%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%fetching tools...%R%
echo.
if not exist "%~dp0bin\checksums.txt" (
  echo   %BAD%bin\checksums.txt missing%R%
  pause>nul
  goto menu
)
set "YTURL="
set "YTHASH="
set "FFURL="
set "FFHASH="
set "DENOURL="
set "DENOHASH="
for /f "usebackq tokens=1,2,3,4 eol=#" %%a in ("%~dp0bin\checksums.txt") do (
  if /i "%%a"=="yt-dlp_windows" (set "YTURL=%%d" & set "YTHASH=%%c")
  if /i "%%a"=="ffmpeg_windows" (set "FFURL=%%d" & set "FFHASH=%%c")
  if /i "%%a"=="deno_windows" (set "DENOURL=%%d" & set "DENOHASH=%%c")
)
where curl.exe >nul 2>&1
if errorlevel 1 (
  echo   %BAD%curl missing%R%
  pause>nul
  goto menu
)
if not exist "yt-dlp.exe" if defined YTURL (
  echo   %MUT%yt-dlp...%R%
  curl -L --max-time 180 -o "yt-dlp.exe.tmp" "%YTURL%" 2>nul
  call :verifyhash "yt-dlp.exe.tmp" "%YTHASH%" "yt-dlp.exe"
)
if not exist "ffmpeg.exe" if defined FFURL (
  echo   %MUT%ffmpeg...%R%
  curl -L --max-time 600 -o "ffmpeg.zip.tmp" "%FFURL%" 2>nul
  call :verifyhash "ffmpeg.zip.tmp" "%FFHASH%" "ffmpeg.zip"
  if exist "ffmpeg.zip" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[IO.Compression.ZipFile]::OpenRead((Resolve-Path 'ffmpeg.zip').Path); $e=$z.Entries | Where-Object { $_.FullName -like '*bin/ffmpeg.exe' } | Select-Object -First 1; if($e){[IO.Compression.ZipFileExtensions]::ExtractToFile($e,'ffmpeg.exe',$true)}; $z.Dispose()"
    del /q "ffmpeg.zip" 2>nul
  )
)
if not exist "deno.exe" if defined DENOURL (
  echo   %MUT%deno...%R%
  curl -L --max-time 300 -o "deno.zip.tmp" "%DENOURL%" 2>nul
  call :verifyhash "deno.zip.tmp" "%DENOHASH%" "deno.zip"
  if exist "deno.zip" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[IO.Compression.ZipFile]::OpenRead((Resolve-Path 'deno.zip').Path); $e=$z.Entries | Where-Object { $_.FullName -eq 'deno.exe' } | Select-Object -First 1; if($e){[IO.Compression.ZipFileExtensions]::ExtractToFile($e,'deno.exe',$true)}; $z.Dispose()"
    del /q "deno.zip" 2>nul
  )
)
echo.
echo   %GOOD%done.%R%
pause>nul
goto menu

:verifyhash
set "TMPF=%~1"
set "EXPECTED=%~2"
set "FINAL=%~3"
if not exist "%TMPF%" exit /b 1
set "ACTUAL="
for /f "skip=1 tokens=* delims=" %%i in ('certutil -hashfile "%TMPF%" SHA256 2^>nul') do (
  if not defined ACTUAL set "ACTUAL=%%i"
)
set "ACTUAL=%ACTUAL: =%"
set "ACTUAL=%ACTUAL:~0,64%"
if /i not "!ACTUAL!"=="%EXPECTED%" (
  del /q "%TMPF%" 2>nul
  exit /b 1
)
move /y "%TMPF%" "%FINAL%" >nul
exit /b 0
