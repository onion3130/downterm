# Add this downterm folder to the user PATH so "downterm" works in new terminals.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File install-path.ps1
#        powershell -NoProfile -ExecutionPolicy Bypass -File install-path.ps1 -Uninstall

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path.TrimEnd('\')

$cmd = Join-Path $Root 'downterm.cmd'
if (-not (Test-Path $cmd)) {
  @"
@echo off
cd /d "%~dp0"
call "%~dp0download.bat" %*
"@ | Set-Content -Path $cmd -Encoding ASCII
}

function Get-UserPathParts {
  $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ([string]::IsNullOrWhiteSpace($cur)) { return @() }
  return @($cur -split ';' | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.TrimEnd('\') })
}

function Set-UserPathParts([string[]]$parts) {
  $joined = ($parts | Where-Object { $_ } ) -join ';'
  [Environment]::SetEnvironmentVariable('Path', $joined, 'User')
}

$parts = @(Get-UserPathParts)

if ($Uninstall) {
  $next = @($parts | Where-Object { $_ -ne $Root })
  Set-UserPathParts $next
  Write-Host "  removed from user PATH: $Root"
  exit 0
}

if ($parts -contains $Root) {
  Write-Host "  already on user PATH"
} else {
  $parts += $Root
  Set-UserPathParts $parts
  Write-Host "  added to user PATH: $Root"
}

# So this session can find it without restarting the whole Windows session
$env:Path = $Root + ';' + $env:Path

Write-Host ""
Write-Host "  entrypoint: $cmd"
Write-Host "  open a NEW terminal, then type:"
Write-Host ""
Write-Host "    downterm"
Write-Host ""
exit 0
