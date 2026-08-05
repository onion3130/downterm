# Add this downterm folder to the user PATH so "downterm" works in new terminals.
# Also ensures downterm.cmd + downterm.ps1 entrypoints exist.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File install-path.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File install-path.ps1 -Uninstall

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path.TrimEnd('\')

function Write-Entrypoints {
  $cmd = Join-Path $Root 'downterm.cmd'
  @"
@echo off
rem PATH entrypoint: typing "downterm" runs the terminal UI
cd /d "%~dp0"
call "%~dp0download.bat" %*
"@ | Set-Content -Path $cmd -Encoding ASCII

  $ps1 = Join-Path $Root 'downterm.ps1'
  @"
# PowerShell entrypoint: typing "downterm" launches the terminal UI.
`$Root = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$bat = Join-Path `$Root 'download.bat'
if (-not (Test-Path `$bat)) { Write-Error 'download.bat missing'; exit 1 }
if (`$args.Count -gt 0) {
  `$joined = (`$args | ForEach-Object { if (`$_ -match '\s') { '"{0}"' -f `$_ } else { `$_ } }) -join ' '
  cmd /c "`"`$bat`" `$joined"
} else {
  cmd /c "`"`$bat`""
}
exit `$LASTEXITCODE
"@ | Set-Content -Path $ps1 -Encoding UTF8
}

function Get-UserPathParts {
  $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ([string]::IsNullOrWhiteSpace($cur)) { return @() }
  return @($cur -split ';' | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.TrimEnd('\') })
}

function Set-UserPathParts([string[]]$parts) {
  $joined = ($parts | Where-Object { $_ }) -join ';'
  [Environment]::SetEnvironmentVariable('Path', $joined, 'User')
  # Notify Windows that env changed (new processes / some explorers pick this up)
  try {
    $sig = @'
[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    $type = Add-Type -MemberDefinition $sig -Name NativeMethodsWin -Namespace Win32 -PassThru -ErrorAction SilentlyContinue
    if ($type) {
      $HWND_BROADCAST = [IntPtr]0xffff
      $WM_SETTINGCHANGE = 0x1a
      $result = [UIntPtr]::Zero
      [void]$type::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
    }
  } catch { }
}

Write-Entrypoints
$parts = @(Get-UserPathParts)

if ($Uninstall) {
  $next = @($parts | Where-Object { $_ -ne $Root })
  Set-UserPathParts $next
  Write-Host "  removed from user PATH:"
  Write-Host "    $Root"
  exit 0
}

if ($parts -contains $Root) {
  Write-Host "  already on user PATH"
} else {
  $parts += $Root
  Set-UserPathParts $parts
  Write-Host "  added to user PATH:"
  Write-Host "    $Root"
}

# Current session
$env:Path = $Root + ';' + $env:Path

Write-Host ""
Write-Host "  entrypoints:"
Write-Host "    $(Join-Path $Root 'downterm.cmd')"
Write-Host "    $(Join-Path $Root 'downterm.ps1')"
Write-Host ""
Write-Host "  IMPORTANT: close this window and open a NEW PowerShell or cmd,"
Write-Host "  then type:"
Write-Host ""
Write-Host "    downterm"
Write-Host ""
exit 0
