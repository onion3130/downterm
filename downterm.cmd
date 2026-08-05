@echo off
rem PATH entrypoint: typing "downterm" runs the terminal UI
cd /d "%~dp0"
call "%~dp0download.bat" %*
