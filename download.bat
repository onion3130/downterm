@echo off
setlocal enabledelayedexpansion
title downterm v2.1
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

mode con: cols=60 lines=22

rem --- Item 6: load config from downterm.conf if present ---
set "CFG_MODE="
set "CFG_QUALITY="
set "CFG_OUTPUT="
if exist "%~dp0downterm.conf" (
  for /f "usebackq eol=# tokens=1,2 delims==" %%a in ("%~dp0downterm.conf") do (
    if /i "%%a"=="MODE"    set "CFG_MODE=%%b"
    if /i "%%a"=="QUALITY" set "CFG_QUALITY=%%b"
    if /i "%%a"=="OUTPUT"  set "CFG_OUTPUT=%%b"
  )
)

rem --- Item 6: parse CLI flags (download.bat <url> [--mode=..] [--quality=..] [--output=..]) ---
set "ARG_URL="
set "ARG_MODE="
set "ARG_QUALITY="
set "ARG_OUTPUT="
set "NONFLAG=0"
for %%a in (%*) do (
  set "TOK=%%a"
  if "!TOK:~0,7!"=="--mode="    set "ARG_MODE=!TOK:~7!"
  if "!TOK:~0,10!"=="--quality=" set "ARG_QUALITY=!TOK:~10!"
  if "!TOK:~0,9!"=="--output="  set "ARG_OUTPUT=!TOK:~9!"
  if not "!TOK:~0,2!"=="--" (
    set /a NONFLAG+=1
    if !NONFLAG! equ 1 set "ARG_URL=!TOK!"
  )
)

rem --- if URL + complete config/flags, run non-interactively ---
if defined ARG_URL (
  set "MODE=%CFG_MODE%"
  if defined ARG_MODE set "MODE=%ARG_MODE%"
  set "QUALITY=%CFG_QUALITY%"
  if defined ARG_QUALITY set "QUALITY=%ARG_QUALITY%"
  if not defined MODE set "MODE=video"
  if not defined QUALITY set "QUALITY=best"
  set "url=!ARG_URL!"
  rem save last url for redo
  > "%~dp0.downterm_last.txt" echo !url!
  goto dodownload
)

:start
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.1%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%a quiet wrapper around yt-dlp.%R%
echo.
echo   %FAINT%url  ? help  t test  r redo  s setup  q quit%R%
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
if /i "!url!"=="q" exit /b 0
if /i "!url!"=="quit" exit /b 0
if /i "!url!"=="exit" exit /b 0

rem --- save last URL ---
> ".downterm_last.txt" echo !url!

rem --- detect batch mode (input is an existing file) ---
if exist "!url!" (
  set "BATCHFILE=!url!"
  goto batchmode
)

rem --- single download: ask type + quality ---
call :asktype
call :askquality
goto dodownload

:dodownload
cls
echo.
echo   %ACC%downterm%R%  %FAINT%v2.1%R%
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!url!" "%FFARG%" "!MODE!" "!QUALITY!" "!ARG_OUTPUT!"
set "ec=!errorlevel!"
echo.
echo   %HAIR%-----------------------------------------------%R%
if !ec! gtr 0 (
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
  set "QUALITY=abest"
  goto :eof
)
echo.
echo   %FAINT%  b = best   1 = 1080p   7 = 720p   4 = 480p%R%
set /p "QUALITY=  %MUT%quality? (b/1/7/4) [%ink%b%MUT%]%R% "
if /i "!QUALITY!"=="1" set "QUALITY=1080" & goto :eof
if /i "!QUALITY!"=="7" set "QUALITY=720" & goto :eof
if /i "!QUALITY!"=="4" set "QUALITY=480" & goto :eof
set "QUALITY=best"
goto :eof

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
goto dodownload

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
echo   %ACC%downterm%R%  %FAINT%v2.1%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%[!CURRENT!/!URLCOUNT!]%R%  %FAINT%!BATCHURL!%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "!BATCHURL!" "%FFARG%" "!MODE!" "!QUALITY!"
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
echo   %FAINT%https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4%R%
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0filter.ps1" "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4" "%FFARG%" "video" "best"
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

:setup
cls
echo.
echo   %ACC%downterm%R%  %FAINT%setup%R%
echo   %HAIR%...............................................%R%
echo.
echo   %MUT%fetching pinned binaries...%R%
echo   %FAINT%see bin/checksums.txt for versions and hashes%R%
echo.

rem --- read checksums.txt and resolve pinned urls ---
set "YTURL="
set "YTHASH="
set "FFURL="
set "FFHASH="
set "DENOURL="
set "DENOHASH="
if not exist "%~dp0bin\checksums.txt" (
  echo   %BAD%bin\checksums.txt not found.%R%
  echo   %FAINT%cannot determine what to fetch. reinstall downterm.%R%
  echo.
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)
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

rem --- ensure curl is available ---
where curl.exe >nul 2>&1
if errorlevel 1 (
  echo   %BAD%curl.exe not found.%R%
  echo   %FAINT%downterm setup needs curl (built into Windows 10+).%R%
  echo.
  echo   %FAINT%press any key...%R%
  pause>nul
  goto start
)

rem --- yt-dlp.exe ---
if exist "yt-dlp.exe" (
  echo   %FAINT%yt-dlp.exe already present, skipping.%R%
) else if defined YTURL (
  echo   %MUT%fetching yt-dlp.exe...%R%
  curl -L -o "yt-dlp.exe.tmp" "%YTURL%" 2>nul
  call :verifyhash "yt-dlp.exe.tmp" "%YTHASH%" "yt-dlp.exe"
  if errorlevel 1 goto setupfail
  echo   %GOOD%yt-dlp.exe verified.%R%
)

rem --- ffmpeg.exe (extract from essentials zip) ---
if exist "ffmpeg.exe" (
  echo   %FAINT%ffmpeg.exe already present, skipping.%R%
) else if defined FFURL (
  echo   %MUT%fetching ffmpeg essentials.zip...%R%
  curl -L -o "ffmpeg.zip.tmp" "%FFURL%" 2>nul
  call :verifyhash "ffmpeg.zip.tmp" "%FFHASH%" "ffmpeg.zip"
  if errorlevel 1 goto setupfail
  echo   %MUT%extracting ffmpeg.exe from zip...%R%
  powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead((Resolve-Path 'ffmpeg.zip').Path); $e=$z.Entries | Where-Object { $_.FullName -like 'bin/ffmpeg.exe' -or $_.FullName -like '*/bin/ffmpeg.exe' } | Select-Object -First 1; if ($e) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, 'ffmpeg.exe', $true) } else { Write-Output 'NOTFOUND' }; $z.Dispose()" 2>nul
  if exist "ffmpeg.exe.tmp" del /q "ffmpeg.exe.tmp" 2>nul
  if exist "ffmpeg.zip" del /q "ffmpeg.zip" 2>nul
  if not exist "ffmpeg.exe" (
    echo   %BAD%ffmpeg.exe not found in essentials zip.%R%
    echo   %FAINT%the gyan.dev build layout may have changed. open an issue at%R%
    echo   %FAINT%github.com/onion3130/downterm/issues%R%
    goto setupfail
  )
  echo   %GOOD%ffmpeg.exe extracted.%R%
)

rem --- deno.exe (optional, extract from deno zip) ---
if exist "deno.exe" (
  echo   %FAINT%deno.exe already present, skipping.%R%
) else if defined DENOURL (
  echo   %MUT%fetching deno.zip...%R%
  curl -L -o "deno.zip.tmp" "%DENOURL%" 2>nul
  call :verifyhash "deno.zip.tmp" "%DENOHASH%" "deno.zip"
  if errorlevel 1 goto setupfail
  echo   %MUT%extracting deno.exe from zip...%R%
  powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead((Resolve-Path 'deno.zip').Path); $e=$z.Entries | Where-Object { $_.FullName -eq 'deno.exe' } | Select-Object -First 1; if ($e) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, 'deno.exe', $true) } else { Write-Output 'NOTFOUND' }; $z.Dispose()" 2>nul
  if exist "deno.zip" del /q "deno.zip" 2>nul
  if not exist "deno.exe" (
    echo   %BAD%deno.exe not found in deno zip.%R%
    echo   %FAINT%optional - yt-dlp will fall back to limited JS retrieval.%R%
  ) else (
    echo   %GOOD%deno.exe extracted.%R%
  )
)

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
rem args: %1 = tmpfile, %2 = expected sha256, %3 = final name
set "TMPF=%~1"
set "EXPECTED=%~2"
set "FINAL=%~3"
set "ACTUAL="
for /f "skip=1 tokens=* delims=" %%i in ('certutil -hashfile "%TMPF%" SHA256 2^>nul') do (
  if not defined ACTUAL set "ACTUAL=%%i"
)
rem certutil echoes hash on second line with leading spaces; strip them
set "ACTUAL=%ACTUAL: =%"
set "ACTUAL=%ACTUAL:~0,64%"
if /i "!ACTUAL!"=="%EXPECTED%" (
  move /y "%TMPF%" "%FINAL%" >nul
  exit /b 0
)
echo   %BAD%checksum mismatch for %FINAL%%R%
echo   %FAINT%expected: %EXPECTED%%R%
echo   %FAINT%actual:   !ACTUAL!%R%
del /q "%TMPF%" 2>nul
exit /b 1

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
echo     %INK%v/a%R%     %FAINT%video or audio (default: video)%R%
echo     %INK%b/1/7/4%R%  %FAINT%best/1080p/720p/480p%R%
echo     %INK%b/m/l%R%    %FAINT%audio: best/medium/low%R%
echo.
echo   %MUT%commands%R%
echo     %INK%?%R%   %FAINT%this screen%R%
echo     %INK%t%R%   %FAINT%self-test (download sample, then delete)%R%
echo     %INK%r%R%   %FAINT%redo last download%R%
echo     %INK%s%R%   %FAINT%setup (fetch yt-dlp.exe, ffmpeg.exe, deno.exe)%R%
echo     %INK%q%R%   %FAINT%quit%R%
echo.
echo   %MUT%requires%R%
echo     %FAINT%- run 's' on first launch to fetch yt-dlp.exe,%R%
echo       %FAINT%ffmpeg.exe, and deno.exe (verified by SHA256)%R%
echo     %FAINT%- PowerShell (for progress bar)%R%
echo.
echo   %HAIR%-----------------------------------------------%R%
echo.
echo   %FAINT%any key to go back.%R%
pause>nul
goto start

rem catch-all: if flow ever falls through, don't close the window
goto die
