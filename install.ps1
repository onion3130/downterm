# downterm installer - Windows
#
#   irm https://raw.githubusercontent.com/onion3130/downterm/main/install.ps1 | iex
#
# Downloads the latest release source, runs setup.ps1 (tools + PATH), so a
# brand-new terminal can run:  downterm

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$Repo   = 'onion3130/downterm'
$Api    = "https://api.github.com/repos/$Repo/releases/latest"
$Target = Join-Path $env:LOCALAPPDATA 'downterm'
$Tmp    = Join-Path $env:TEMP ('downterm-' + [guid]::NewGuid().ToString('N'))

function Write-Step($m) { Write-Host "  $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "  $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "  $m" -ForegroundColor Yellow }

Write-Host ''
Write-Host '  downterm installer'
Write-Host '  ..........................................'
Write-Host ''

$tag = $null
try {
  $rel = Invoke-RestMethod -Uri $Api -Headers @{ 'User-Agent' = 'downterm-installer' }
  $tag = $rel.tag_name
} catch {
  Write-Warn 'could not reach GitHub - check your connection, then try again.'
  exit 1
}
Write-Step "latest release:  $tag"

New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
$zip = Join-Path $Tmp 'source.zip'
Write-Step 'downloading downterm ...'
try {
  Invoke-WebRequest -Uri "https://github.com/$Repo/archive/refs/tags/$tag.zip" -OutFile $zip
} catch {
  Write-Warn "download failed - got: $($_.Exception.Message)"
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
  exit 1
}

Write-Step 'installing ...'
$unzip = Join-Path $Tmp 'u'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $unzip)
$srcRoot = Get-ChildItem -LiteralPath $unzip -Directory | Select-Object -First 1
if (-not $srcRoot) { Write-Warn 'source package was empty.'; Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue; exit 1 }

New-Item -ItemType Directory -Path $Target -Force | Out-Null
Copy-Item -Path (Join-Path $srcRoot.FullName '*') -Destination $Target -Recurse -Force

Write-Step 'running setup (tools + PATH) ...'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Target 'setup.ps1')
if ($LASTEXITCODE -ne 0) {
  Write-Warn 'setup did not finish cleanly; run "setup.ps1" manually in this folder:'
  Write-Warn "  $Target"
  exit 1
}

Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue

Write-Host ''
Write-Ok 'done.'
Write-Host ''
Write-Host '  1. Close this window'
Write-Host '  2. Open a NEW PowerShell or cmd'
Write-Host '  3. Type:  downterm'
Write-Host ''
Write-Host '  To remove later:'
Write-Host "      download.bat --uninstall   (from $Target)"
Write-Host "      then delete the folder  $Target"
Write-Host ''
exit 0