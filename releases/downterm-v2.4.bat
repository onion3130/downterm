@echo off
setlocal enabledelayedexpansion
title downterm v2.4
cd /d "%~dp0"
rem safety: never let the window close without a pause
goto main
:die
echo.
echo   %FAINT%window closing. press any key...%R%
pause>nul
exit /b 0
:main

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

mode con: cols=60 lines=24

rem --- load config from downterm.conf if present ---
set "CFG_MODE="
set "CFG_QUALITY="
set "CFG_OUTPUT="
set "CFG_SUBS="
set "CFG_FORCE="
set "CFG_SPONSOR="
if exist "%~dp0downterm.conf" (
  for /f "usebackq eol=# tokens=1,2 delims==" %%a in ("%~dp0downterm.conf") do (
    if /i "%%a"=="MODE"         set "CFG_MODE=%%b"
    if /i "%%a"=="QUALITY"      set "CFG_QUALITY=%%b"
    if /i "%%a"=="OUTPUT"       set "CFG_OUTPUT=%%b"
    if /i "%%a"=="SUBS"         set "CFG_SUBS=%%b"
    if /i "%%a"=="FORCE"        set "CFG_FORCE=%%b"
    if /i "%%a"=="SPONSORBLOCK" set "CFG_SPONSOR=%%b"
  )
)

rem --- CLI: download.bat <url> [--mode=] [--quality=] [--output=] [--subs] [--force] [--sponsorblock] [--setup] [--version] ---
set "ARG_URL="
set "ARG_MODE="
set "ARG_QUALITY="
set "ARG_OUTPUT="
set "ARG_SUBS="
set "ARG_FORCE="
set "ARG_SPONSOR="
set "ARG_OP="
set "NONFLAG=0"
for %%a in (%*) do (
  set "TOK=%%a"
  if "!TOK:~0,7!"=="--mode="         set "ARG_MODE=!TOK:~7!"
  if "!TOK:~0,10!"=="--quality="     set "ARG_QUALITY=!TOK:~10!"
  if "!TOK:~0,9!"=="--output="       set "ARG_OUTPUT=!TOK:~9!"
  if /i "!TOK!"=="--subs"            set "ARG_SUBS=1"
  if /i "!TOK!"=="--force"           set "ARG_FORCE=1"
  if /i "!TOK!"=="--sponsorblock"    set "ARG_SPONSOR=1"
  if /i "!TOK!"=="--setup"           set "ARG_OP=setup"
  if /i "!TOK!"=="--version"         set "ARG_OP=version"
  if not "!TOK:~0,2!"=="--" (
    set /a NONFLAG+=1
    if !NONFLAG! equ 1 set "ARG_URL=!TOK!"
  )
)

if /i "!ARG_OP!"=="version" (
  call :showversion
  exit /b 0
)

if /i "!ARG_OP!"=="setup" (
  call :setup
  exit /b 0
)

rem defaults from config then flags
set "MODE=%CFG_MODE%"
if defined ARG_MODE set "MODE=%ARG_MODE%"
set "QUALITY=%CFG_QUALITY%"
if defined ARG_QUALITY set "QUALITY=%ARG_QUALITY%"
set "SUBS=%CFG_SUBS%"
if defined ARG_SUBS set "SUBS=%ARG_SUBS%"
set "FORCE=%CFG_FORCE%"
if defined ARG_FORCE set "FORCE=%ARG_FORCE%"
set "SPONSOR=%CFG_SPONSOR%"
if defined ARG_SPONSOR set "SPONSOR=%ARG_SPONSOR%"
if defined CFG_OUTPUT if not defined ARG_OUTPUT set "ARG_OUTPUT=%CFG_OUTPUT%"
if not defined MODE set "MODE=video"
if not defined QUALITY set "QUALITY=best"
if not defined SUBS set "SUBS=0"
if not defined FORCE set "FORCE=0"
if not defined SPONSOR set "SPONSOR=0"

rem --- non-interactive: URL present ---
if defined ARG_URL (
  set "url=!ARG_URL!"
  call :savelast
  call :savehistory
  goto dodownload
)

:start
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.4%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%a quiet wrapper around yt-dlp.%R%
echo.
echo   %FAINT%url  p paste  h history  o open  i info%R%
echo   %FAINT%? help  t test  r redo  s setup  q quit%R%
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
if /i "!url!"=="r" goto redolast
if /i "!url!"=="redo" goto redolast
if /i "!url!"=="s" goto setup
if /i "!url!"=="setup" goto setup
if /i "!url!"=="p" goto pasteclip
if /i "!url!"=="paste" goto pasteclip
if /i "!url!"=="h" goto showhistory
if /i "!url!"=="history" goto showhistory
if /i "!url!"=="o" goto openfolder
if /i "!url!"=="open" goto openfolder
if /i "!url!"=="i" goto infomode
if /i "!url!"=="info" goto infomode
if /i "!url!"=="q" exit /b 0
if /i "!url!"=="quit" exit /b 0
if /i "!url!"=="exit" exit /b 0

call :savelast
call :savehistory

if exist "!url!" (
  set "BATCHFILE=!url!"
  goto batchmode
)

call :asktype
call :askquality
call :askextras
goto dodownload

:dodownload
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.4%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%acquiring%R%  %FAINT%!url!%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.

if not exist "yt-dlp.exe" (
  echo   %BAD%yt-dlp.exe not found.%R%
  echo   %FAINT%run 's' to fetch it, or see bin/checksums.txt%R%
  echo.
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)

set "FFARG="
if exist "ffmpeg.exe" set "FFARG=.\ffmpeg.exe"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!url!" "%FFARG%" "!MODE!" "!QUALITY!" "!ARG_OUTPUT!" "!SUBS!" "!FORCE!" "!SPONSOR!"
set "ec=!errorlevel!"
echo.
echo   %HAIR%-----------------------------------------------%R%
if !ec! gtr 0 (
  echo   %WARN%finished with warnings.%R%  %FAINT%see error code above%R%
) else (
  if defined ARG_OUTPUT (
    echo   %GOOD%saved.%R%  %FAINT%!ARG_OUTPUT!%R%
  ) else (
    echo   %GOOD%saved.%R%  %FAINT%next to yt-dlp.exe%R%
  )
)
echo.
echo   %FAINT%any key to run again.%R%
pause>nul
goto start

:asktype
echo.
echo   %FAINT%  v = video   a = audio (mp3)%R%
set /p "MODE=  %MUT%video or audio? (v/a) [%ink%v%MUT%]%R% "
if /i "!MODE!"=="a" set "MODE=audio" & goto :eof
set "MODE=video"
goto :eof

:askquality
if /i "!MODE!"=="audio" (
  echo.
  echo   %FAINT%  b = best   m = medium   l = low%R%
  set /p "QUALITY=  %MUT%audio quality? (b/m/l) [%ink%b%MUT%]%R% "
  if /i "!QUALITY!"=="m" set "QUALITY=medium" & goto :eof
  if /i "!QUALITY!"=="l" set "QUALITY=low" & goto :eof
  set "QUALITY=best"
  goto :eof
)
echo.
echo   %FAINT%  b=best  k=4K  2=1440  1=1080  7=720  4=480%R%
set /p "QUALITY=  %MUT%quality? (b/k/2/1/7/4) [%ink%b%MUT%]%R% "
if /i "!QUALITY!"=="k" set "QUALITY=2160" & goto :eof
if /i "!QUALITY!"=="2" set "QUALITY=1440" & goto :eof
if /i "!QUALITY!"=="1" set "QUALITY=1080" & goto :eof
if /i "!QUALITY!"=="7" set "QUALITY=720" & goto :eof
if /i "!QUALITY!"=="4" set "QUALITY=480" & goto :eof
set "QUALITY=best"
goto :eof

:askextras
if /i "!MODE!"=="audio" (
  set "SUBS=0"
  set "SPONSOR=0"
  goto :askforce
)
echo.
echo   %FAINT%  y = yes   n = no%R%
set /p "SUBS=  %MUT%embed English subs? (y/n) [%ink%n%MUT%]%R% "
if /i "!SUBS!"=="y" (set "SUBS=1") else (set "SUBS=0")
echo.
set /p "SPONSOR=  %MUT%SponsorBlock remove? (y/n) [%ink%n%MUT%]%R% "
if /i "!SPONSOR!"=="y" (set "SPONSOR=1") else (set "SPONSOR=0")
:askforce
echo.
set /p "FORCE=  %MUT%overwrite if exists? (y/n) [%ink%n%MUT%]%R% "
if /i "!FORCE!"=="y" (set "FORCE=1") else (set "FORCE=0")
goto :eof

:savelast
> "%~dp0.downterm_last.txt" echo !url!
goto :eof

:savehistory
if "!url!"=="" goto :eof
echo !url!>> "%~dp0.downterm_history"
rem keep last ~30 lines
if exist "%~dp0.downterm_history" (
  powershell -NoProfile -Command "$p='%~dp0.downterm_history'; if (Test-Path $p) { $l=Get-Content $p | Where-Object { $_.Trim() -ne '' }; if ($l.Count -gt 30) { $l[-30..-1] | Set-Content $p } }"
)
goto :eof

:pasteclip
set "url="
for /f "usebackq delims=" %%c in (`powershell -NoProfile -Command "try { (Get-Clipboard -Raw).Trim() } catch { '' }"`) do set "url=%%c"
if "!url!"=="" (
  echo.
  echo   %BAD%clipboard empty.%R%
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)
echo.
echo   %MUT%clipboard:%R%  %FAINT%!url!%R%
echo.
call :savelast
call :savehistory
if exist "!url!" (
  set "BATCHFILE=!url!"
  goto batchmode
)
call :asktype
call :askquality
call :askextras
goto dodownload

:showhistory
cls
echo.
echo   %ACC%downterm%R%  %FAINT%history%R%
echo   %HAIR%...............................................%R%
echo.
if not exist "%~dp0.downterm_history" (
  echo   %FAINT%  no history yet.%R%
  echo.
  echo   %FAINT%  any key...%R%
  pause>nul
  goto start
)
set "HCOUNT=0"
for /f "usebackq delims=" %%h in ("%~dp0.downterm_history") do (
  set /a HCOUNT+=1
  set "H!HCOUNT!=%%h"
)
if !HCOUNT! lss 1 (
  echo   %FAINT%  no history yet.%R%
  echo.
  echo   %FAINT%  any key...%R%
  pause>nul
  goto start
)
set "SHOWFROM=1"
if !HCOUNT! gtr 12 set /a SHOWFROM=HCOUNT-11
set "N=0"
for /l %%i in (!SHOWFROM!,1,!HCOUNT!) do (
  set /a N+=1
  call set "HLINE=%%H%%i%%"
  echo   !N!  !HLINE!
)
echo.
set /p "HPICK=  %MUT%number to redownload (or enter)%R% "
if "!HPICK!"=="" goto start
set /a IDX=SHOWFROM+HPICK-1
if !IDX! lss 1 goto start
if !IDX! gtr !HCOUNT! goto start
call set "url=%%H!IDX!%%"
if "!url!"=="" goto start
echo.
echo   %MUT%picked:%R%  %FAINT%!url!%R%
call :savelast
call :asktype
call :askquality
call :askextras
goto dodownload

:openfolder
set "OPENDIR=%~dp0"
if defined ARG_OUTPUT set "OPENDIR=!ARG_OUTPUT!"
if defined CFG_OUTPUT if not defined ARG_OUTPUT set "OPENDIR=!CFG_OUTPUT!"
if not exist "!OPENDIR!" set "OPENDIR=%~dp0"
start "" explorer "!OPENDIR!"
goto start

:infomode
echo.
set /p "url=  %MUT%url to inspect%R%  %INK%<%R% "
if "!url!"=="" goto start
if not exist "yt-dlp.exe" (
  echo   %BAD%yt-dlp.exe not found.%R%
  pause>nul
  goto start
)
echo.
echo   %MUT%fetching info...%R%
echo.
yt-dlp.exe --no-download --print "%%(title)s" --print "%%(duration_string)s" --print "%%(uploader)s" --print "%%(webpage_url)s" "!url!" 2>nul
if errorlevel 1 (
  echo   %WARN%could not fetch info.%R%
) else (
  echo.
  echo   %FAINT%  d = download this   other = back%R%
  set /p "INEXT=  %MUT%next?%R% "
  if /i "!INEXT!"=="d" (
    call :savelast
    call :savehistory
    call :asktype
    call :askquality
    call :askextras
    goto dodownload
  )
)
echo.
echo   %FAINT%any key...%R%
pause>nul
goto start

:redolast
if not exist ".downterm_last.txt" (
  echo.
  echo   %FAINT%  no previous download to redo.%R%
  echo   %FAINT%  press any key...%R%
  pause>nul
  goto start
)
set /p "url=" < ".downterm_last.txt"
if "!url!"=="" (
  echo.
  echo   %FAINT%  no previous download to redo.%R%
  echo   %FAINT%  press any key...%R%
  pause>nul
  goto start
)
echo.
echo   %MUT%redoing:%R%  %FAINT%!url!%R%
echo.
call :asktype
call :askquality
call :askextras
goto dodownload

:batchmode
echo.
echo   %MUT%batch file detected.%R%  %FAINT%!BATCHFILE!%R%
call :asktype
call :askquality
call :askextras

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
echo   %ACC%downterm%R%  %FAINT%v2.4%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%[!CURRENT!/!URLCOUNT!]%R%  %FAINT%!BATCHURL!%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.
set "url=!BATCHURL!"
call :savehistory
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!BATCHURL!" "%FFARG%" "!MODE!" "!QUALITY!" "!ARG_OUTPUT!" "!SUBS!" "!FORCE!" "!SPONSOR!"
set "ec=!errorlevel!"
echo.
if !ec! equ 0 (
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
echo   %FAINT%https://media.w3.org/2010/05/sintel/trailer.mp4%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.

if not exist "yt-dlp.exe" (
  echo   %BAD%yt-dlp.exe not found.%R%
  echo   %FAINT%run 's' to fetch it, or see bin/checksums.txt%R%
  echo.
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)

set "FFARG="
if exist "ffmpeg.exe" set "FFARG=.\ffmpeg.exe"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "https://media.w3.org/2010/05/sintel/trailer.mp4" "%FFARG%" "video" "best" "" "0" "1" "0"
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
for %%x in (*.mp4 *.mkv *.mp3 *.m4a) do (
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

:showversion
echo downterm v2.4
echo.
echo   %FAINT%pinned (bin/checksums.txt):%R%
echo     yt-dlp  2026.07.04
echo     ffmpeg  9.0
echo     deno    2.9.4
echo.
echo   %FAINT%installed:%R%
if exist "yt-dlp.exe" (
  for /f "delims=" %%v in ('yt-dlp.exe --version 2^>nul') do set "YTVER=%%v"
  echo     yt-dlp  !YTVER!
) else (
  echo     yt-dlp  %WARN%not installed - run 's'%R%
)
if exist "ffmpeg.exe" (
  set "FFVER="
  for /f "tokens=1-3" %%a in ('ffmpeg.exe -version 2^>nul') do (
    if not defined FFVER set "FFVER=%%a %%b %%c"
  )
  if defined FFVER (
    echo     ffmpeg  !FFVER!
  ) else (
    echo     ffmpeg  %WARN%present but no version output%R%
  )
) else (
  echo     ffmpeg  %WARN%not installed - run 's'%R%
)
if exist "deno.exe" (
  for /f "delims=" %%v in ('deno.exe --version 2^>nul ^| findstr "^deno"') do set "DENOVER=%%v"
  echo     deno    !DENOVER!
) else (
  echo     deno    %WARN%not installed - run 's'%R%
)
exit /b 0

:setup
cls
echo.
echo   %ACC%downterm%R%  %FAINT%setup%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%fetching pinned binaries...%R%
echo   %FAINT%see bin/checksums.txt for versions and hashes%R%
echo.

set "YTURL="
set "YTHASH="
set "FFURL="
set "FFHASH="
set "DENOURL="
set "DENOHASH="
if not exist "%~dp0bin\checksums.txt" goto :nofile
goto :hfile
:nofile
echo   %BAD%bin\checksums.txt not found.%R%
echo   %FAINT%cannot determine what to fetch. reinstall downterm.%R%
echo.
echo   %FAINT%press any key...%R%
pause>nul
goto start
:hfile
for /f "usebackq tokens=1,2,3,4 eol=#" %%a in ("%~dp0bin\checksums.txt") do (
  if /i "%%a"=="yt-dlp_windows" (
    set "YTURL=%%d"
    set "YTHASH=%%c"
  )
  if /i "%%a"=="ffmpeg_windows" (
    set "FFURL=%%d"
    set "FFHASH=%%c"
  )
  if /i "%%a"=="deno_windows" (
    set "DENOURL=%%d"
    set "DENOHASH=%%c"
  )
)

where curl.exe >nul 2>&1
if errorlevel 1 goto :nocurl
goto :hcurl
:nocurl
echo   %BAD%curl.exe not found.%R%
echo   %FAINT%downterm setup needs curl ^(built into Windows 10+^).%R%
echo.
echo   %FAINT%press any key...%R%
pause>nul
goto start
:hcurl

if exist "yt-dlp.exe" (
  echo   %FAINT%yt-dlp.exe already present, skipping.%R%
  goto :ytok
)
if not defined YTURL goto :ytok
echo   %MUT%fetching yt-dlp.exe...%R%
curl -L --max-time 180 -o "yt-dlp.exe.tmp" "%YTURL%" 2>nul
call :verifyhash "yt-dlp.exe.tmp" "%YTHASH%" "yt-dlp.exe"
if errorlevel 1 goto setupfail
echo   %GOOD%yt-dlp.exe verified.%R%
:ytok

if exist "ffmpeg.exe" (
  echo   %FAINT%ffmpeg.exe already present, skipping.%R%
  goto :ffok
)
if not defined FFURL goto :ffok
echo   %MUT%fetching ffmpeg essentials.zip...%R%
curl -L --max-time 600 -o "ffmpeg.zip.tmp" "%FFURL%" 2>nul
if errorlevel 1 goto :ffskip
call :verifyhash "ffmpeg.zip.tmp" "%FFHASH%" "ffmpeg.zip"
if errorlevel 1 goto :ffskip
echo   %MUT%extracting ffmpeg.exe from zip...%R%
call :extractffmpeg
if exist "ffmpeg.exe.tmp" del /q "ffmpeg.exe.tmp" 2>nul
if exist "ffmpeg.zip" del /q "ffmpeg.zip" 2>nul
if exist "ffmpeg.exe" (
  echo   %GOOD%ffmpeg.exe extracted.%R%
  goto :ffok
)
:ffskip
echo   %WARN%ffmpeg.exe not available; skipping (optional for plain mp4 downloads).%R%
if exist "ffmpeg.zip.tmp" del /q "ffmpeg.zip.tmp" 2>nul
if exist "ffmpeg.zip" del /q "ffmpeg.zip" 2>nul
:ffok

if exist "deno.exe" (
  echo   %FAINT%deno.exe already present, skipping.%R%
  goto :denook
)
if not defined DENOURL goto :denook
echo   %MUT%fetching deno.zip...%R%
curl -L --max-time 300 -o "deno.zip.tmp" "%DENOURL%" 2>nul
if errorlevel 1 goto :denoskip
call :verifyhash "deno.zip.tmp" "%DENOHASH%" "deno.zip"
if errorlevel 1 goto :denoskip
echo   %MUT%extracting deno.exe from zip...%R%
call :extractdeno
if exist "deno.zip" del /q "deno.zip" 2>nul
if exist "deno.exe" (
  echo   %GOOD%deno.exe extracted.%R%
  goto :denook
)
:denoskip
echo   %WARN%deno.exe not available; skipping (optional).%R%
if exist "deno.zip.tmp" del /q "deno.zip.tmp" 2>nul
if exist "deno.zip" del /q "deno.zip" 2>nul
:denook

echo.
echo   %GOOD%setup complete.%R%  %FAINT%you can now paste a url.%R%
echo.
echo   %FAINT%press any key...%R%
pause>nul
goto start

:setupfail
if exist "yt-dlp.exe.tmp" del /q "yt-dlp.exe.tmp" 2>nul
if exist "ffmpeg.zip.tmp" del /q "ffmpeg.zip.tmp" 2>nul
if exist "ffmpeg.zip" del /q "ffmpeg.zip" 2>nul
if exist "deno.zip.tmp" del /q "deno.zip.tmp" 2>nul
if exist "deno.zip" del /q "deno.zip" 2>nul
echo.
echo   %BAD%setup failed.%R%  %FAINT%see checksum mismatch above.%R%
echo   %FAINT%delete the bad binary and re-run 's'. if it still fails,%R%
echo   %FAINT%the pinned build may have been re-uploaded. open an issue:%R%
echo   %FAINT%github.com/onion3130/downterm/issues%R%
echo.
echo   %FAINT%press any key...%R%
pause>nul
goto start

:verifyhash
set "TMPF=%~1"
set "EXPECTED=%~2"
set "FINAL=%~3"
set "ACTUAL="
for /f "skip=1 tokens=* delims=" %%i in ('certutil -hashfile "%TMPF%" SHA256 2^>nul') do (
  if not defined ACTUAL set "ACTUAL=%%i"
)
set "ACTUAL=%ACTUAL: =%"
set "ACTUAL=%ACTUAL:~0,64%"
if /i not "!ACTUAL!"=="%EXPECTED%" goto :hashbad
move /y "%TMPF%" "%FINAL%" >nul
exit /b 0
:hashbad
echo   %BAD%checksum mismatch for %FINAL%%R%
echo   %FAINT%expected: %EXPECTED%%R%
echo   %FAINT%actual:   !ACTUAL!%R%
del /q "%TMPF%" 2>nul
exit /b 1

:extractffmpeg
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead((Resolve-Path 'ffmpeg.zip').Path); $e=$z.Entries | Where-Object { $_.FullName -like 'bin/ffmpeg.exe' -or $_.FullName -like '*/bin/ffmpeg.exe' } | Select-Object -First 1; if ($e) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, 'ffmpeg.exe', $true) } else { Write-Output 'NOTFOUND' }; $z.Dispose()"
exit /b 0

:extractdeno
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead((Resolve-Path 'deno.zip').Path); $e=$z.Entries | Where-Object { $_.FullName -eq 'deno.exe' } | Select-Object -First 1; if ($e) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, 'deno.exe', $true) } else { Write-Output 'NOTFOUND' }; $z.Dispose()"
exit /b 0

:help
cls
echo.
echo   %ACC%downterm%R%  %FAINT%help  v2.4%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%usage%R%
echo     %INK%<%R%  %FAINT%url, then enter%R%
echo     %INK%<%R%  %FAINT%urls.txt  (batch mode)%R%
echo.
echo   %MUT%prompts%R%
echo     %INK%v/a%R%        %FAINT%video or audio%R%
echo     %INK%b/k/2/1/7/4%R% %FAINT%best/4K/1440/1080/720/480%R%
echo     %INK%subs%R%       %FAINT%embed English subtitles%R%
echo     %INK%sponsor%R%    %FAINT%SponsorBlock cleanup%R%
echo     %INK%force%R%      %FAINT%overwrite existing file%R%
echo.
echo   %MUT%commands%R%
echo     %INK%p%R%  %FAINT%paste URL from clipboard%R%
echo     %INK%h%R%  %FAINT%history (pick a past URL)%R%
echo     %INK%o%R%  %FAINT%open download folder%R%
echo     %INK%i%R%  %FAINT%info (title/duration) then optional download%R%
echo     %INK%?%R%  %FAINT%this screen%R%
echo     %INK%t%R%  %FAINT%self-test%R%
echo     %INK%r%R%  %FAINT%redo last%R%
echo     %INK%s%R%  %FAINT%setup binaries%R%
echo     %INK%q%R%  %FAINT%quit%R%
echo.
echo   %MUT%flags%R%
echo     %FAINT%--mode= --quality= --output= --subs --force --sponsorblock%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.
echo   %FAINT%any key to go back.%R%
pause>nul
goto start

goto die
