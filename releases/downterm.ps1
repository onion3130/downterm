# PowerShell entrypoint: typing "downterm" launches the terminal UI.
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bat = Join-Path $Root 'download.bat'
if (-not (Test-Path $bat)) { Write-Error 'download.bat missing'; exit 1 }
if ($args.Count -gt 0) {
  $joined = ($args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' '
  cmd /c ""$bat" $joined"
} else {
  cmd /c ""$bat""
}
exit $LASTEXITCODE
