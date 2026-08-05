@echo off
setlocal enabledelayedexpansion
title downterm
cd /d "%~dp0"

rem downterm 3.3.0 — minimal terminal UI only (no window GUI)
rem   downterm            → menu
rem   downterm --version
rem   downterm --setup
rem   downterm --install  → add this folder to user PATH (type "downterm" anywhere)

if /i "%~1"=="--version" (
  echo downterm 3.3.0
  exit /b 0
)
if /i "%~1"=="--setup" goto setup
if /i "%~1"=="--install" goto install_path
if /i "%~1"=="--uninstall" goto uninstall_path

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

mode con: cols=56 lines=24

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

rem first launch: offer PATH install so "downterm" works in PowerShell/cmd
if not exist "%~dp0.downterm_path_ok" call :maybe_install_path

:menu
cls
echo.
echo   %ACC%downterm%R%  %FAINT%3.3.0%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%copy a link, then pick a number.%R%
echo.
echo   %INK%1%R%  %FAINT%paste · best video%R%
echo   %INK%2%R%  %FAINT%paste · pick quality%R%
echo   %INK%3%R%  %FAINT%paste · audio only%R%
echo   %INK%4%R%  %FAINT%history%R%
echo   %INK%5%R%  %FAINT%open folder%R%
echo   %INK%6%R%  %FAINT%setup tools%R%
echo   %INK%7%R%  %FAINT%add to PATH  →  type  downterm  anywhere%R%
echo   %INK%8%R%  %FAINT%help%R%
echo   %INK%9%R%  %FAINT%quit%R%
echo.
if not exist "%~dp0.downterm_path_ok" (
  echo   %WARN%tip:%R% %FAINT%press 7 once so PowerShell finds "downterm"%R%
  echo.
)
choice /c 123456789 /n /m "  %MUT%>%R% "
set "C=!errorlevel!"
if "!C!"=="1" goto quick_video
if "!C!"=="2" goto pick_video
if "!C!"=="3" goto quick_audio
if "!C!"=="4" goto history
if "!C!"=="5" goto openfolder
if "!C!"=="6" goto setup
if "!C!"=="7" goto install_path
if "!C!"=="8" goto help
if "!C!"=="9" exit /b 0
goto menu

:getclip
set "url="
for /f "usebackq delims=" %%c in (`powershell -NoProfile -Command "try { $t=(Get-Clipboard -Raw); if ($t -match 'https?://\S+') { $matches[0].TrimEnd([char]41,[char]46,[char]44,[char]34) } } catch { '' }"`) do set "url=%%c"
if "!url!"=="" (
  echo.
  echo   %BAD%no link in clipboard.%R%
  echo   %FAINT%copy a video link, then try again.%R%
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
echo   %FAINT%extras%R%
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
  echo   %BAD%yt-dlp.exe missing — press 6 for setup%R%
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

:maybe_install_path
cls
echo.
echo   %ACC%downterm%R%  %FAINT%3.3.0%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%make typing%R%  %INK%downterm%R%  %MUT%work in PowerShell / cmd?%R%
echo.
echo   %FAINT%adds this folder to your user PATH once.%R%
echo   %FAINT%%~dp0%R%
echo.
echo   %INK%Y%R%  yes, add PATH now
echo   %INK%N%R%  not now
echo.
choice /c YN /n /m "  %MUT%>%R% "
if errorlevel 2 (
  > "%~dp0.downterm_path_ok" echo skipped
  goto :eof
)
call :do_install_path
> "%~dp0.downterm_path_ok" echo installed
echo.
echo   %FAINT%any key to continue to menu...%R%
pause>nul
goto :eof

:do_install_path
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-path.ps1"
if errorlevel 1 (
  echo   %BAD%could not update PATH%R%
  exit /b 1
)
> "%~dp0.downterm_path_ok" echo installed
echo   %GOOD%done.%R%
echo   %WARN%close this window, open a NEW PowerShell, type:%R%  %INK%downterm%R%
exit /b 0

:install_path
cls
echo.
echo   %ACC%add to PATH%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%after this, any NEW terminal can run:%R%
echo.
echo     %INK%downterm%R%
echo.
echo   %FAINT%folder:%R%
echo   %FAINT%%~dp0%R%
echo.
call :do_install_path
echo.
echo   %FAINT%any key...%R%
pause>nul
goto menu

:uninstall_path
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-path.ps1" -Uninstall
del /q "%~dp0.downterm_path_ok" 2>nul
exit /b 0

:help
cls
echo.
echo   %ACC%help%R%  %FAINT%3.3.0%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%terminal only — number menu, no window app%R%
echo.
echo   1. copy a video link in your browser
echo   2. type  %INK%downterm%R%  ^(after PATH install^)
echo   3. press %INK%1%R% for best video
echo.
echo   %MUT%first time / PATH%R%
echo     double-click  %INK%setup.bat%R%  ^(tools + PATH^)
echo     or press %INK%7%R% /  download.bat --install  ^(PATH only^)
echo     then open a NEW PowerShell → type:  downterm
echo.
echo   %MUT%if PowerShell still says not recognized%R%
echo     - open a brand-new terminal after setup
echo     - re-run:  setup.bat -PathOnly
echo.
echo   %MUT%keys%R%
echo     1 best video   2 quality   3 audio
echo     4 history      5 folder    6 setup
echo     7 add to PATH  8 help      9 quit
echo.
echo   %FAINT%any key...%R%
pause>nul
goto menu

:setup
cls
echo.
echo   %ACC%setup%R%
echo   %HAIR%..........................................%R%
echo.
echo   %MUT%tools + PATH  ^(same as setup.bat^)%R%
echo.
if exist "%~dp0setup.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
) else (
  echo   %BAD%setup.ps1 missing — run setup.bat from a full clone%R%
)
echo.
echo   %FAINT%any key...%R%
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
