# PowerShell entrypoint: typing "downterm" in PowerShell runs the terminal UI.
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bat = Join-Path $Root 'download.bat'
if (-not (Test-Path $bat)) {
  Write-Error "download.bat not found next to downterm.ps1"
  exit 1
}
# Forward args; empty args open the menu
$argLine = ($args | ForEach-Object {
  if ($_ -match '\s') { '"{0}"' -f ($_ -replace '"', '\"') } else { $_ }
}) -join ' '
if ($argLine) {
  cmd /c "`"$bat`" $argLine"
} else {
  cmd /c "`"$bat`""
}
exit $LASTEXITCODE
