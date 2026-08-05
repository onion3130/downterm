# downterm setup (Windows)
# - fetches yt-dlp / ffmpeg / deno (if missing)
# - ALWAYS adds this folder to user PATH so "downterm" works
#
# Run:
#   setup.bat
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1 -PathOnly
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1 -SkipPath

param(
  [switch]$PathOnly,   # only PATH / entrypoints (manual re-install)
  [switch]$SkipPath,   # tools only, no PATH
  [switch]$ForceTools  # re-download tools even if present
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path.TrimEnd('\')
Set-Location $Root

function Write-Step($msg) { Write-Host "  $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  $msg" -ForegroundColor Yellow }
function Write-Bad($msg) { Write-Host "  $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  downterm setup" -ForegroundColor White
Write-Host "  .........................................." -ForegroundColor DarkGray
Write-Host ""

# ---------- tools ----------
if (-not $PathOnly) {
  $checksums = Join-Path $Root 'bin\checksums.txt'
  if (-not (Test-Path $checksums)) {
    Write-Bad "bin\checksums.txt missing — cannot fetch tools."
    exit 1
  }

  function Get-Pin($key) {
    Get-Content $checksums | ForEach-Object {
      $line = $_.Trim()
      if ($line -eq '' -or $line.StartsWith('#')) { return }
      $p = $line -split '\s+', 4
      if ($p.Count -ge 4 -and $p[0] -eq $key) {
        return [pscustomobject]@{ Version = $p[1]; Hash = $p[2]; Url = $p[3] }
      }
    } | Select-Object -First 1
  }

  function Get-Sha256($path) {
    (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLowerInvariant()
  }

  function Get-FileVerified($destName, $pin, $isZip, $extractScript) {
    $dest = Join-Path $Root $destName
    if ((Test-Path $dest) -and -not $ForceTools) {
      Write-Host "  $destName already present — skip"
      return
    }
    if (-not $pin) {
      Write-Warn "no pin for $destName"
      return
    }
    Write-Step "fetching $destName ..."
    $tmp = Join-Path $Root ($destName + '.tmp')
    if ($isZip) { $tmp = Join-Path $Root ($destName + '.zip.tmp') }
    try {
      curl.exe -L --max-time 600 -o $tmp $pin.Url 2>$null
      if (-not (Test-Path $tmp)) { throw "download failed" }
      $actual = Get-Sha256 $tmp
      if ($actual -ne $pin.Hash.ToLowerInvariant()) {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        throw "checksum mismatch for $destName"
      }
      if ($isZip) {
        $zipPath = Join-Path $Root ($destName + '.zip')
        Move-Item -Force $tmp $zipPath
        & $extractScript $zipPath
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
      } else {
        Move-Item -Force $tmp $dest
      }
      if (Test-Path $dest) { Write-Ok "$destName ok" } else { Write-Warn "$destName missing after extract" }
    } catch {
      Write-Warn $_.Exception.Message
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
  }

  if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    Write-Bad "curl.exe not found (needed for setup). Install Windows curl or use a full release zip."
  } else {
    Get-FileVerified 'yt-dlp.exe' (Get-Pin 'yt-dlp_windows') $false $null

    Get-FileVerified 'ffmpeg.exe' (Get-Pin 'ffmpeg_windows') $true {
      param($zip)
      Add-Type -AssemblyName System.IO.Compression.FileSystem
      $z = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $zip).Path)
      try {
        $e = $z.Entries | Where-Object { $_.FullName -like '*bin/ffmpeg.exe' } | Select-Object -First 1
        if ($e) {
          [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $Root 'ffmpeg.exe'), $true)
        }
      } finally { $z.Dispose() }
    }

    Get-FileVerified 'deno.exe' (Get-Pin 'deno_windows') $true {
      param($zip)
      Add-Type -AssemblyName System.IO.Compression.FileSystem
      $z = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $zip).Path)
      try {
        $e = $z.Entries | Where-Object { $_.FullName -eq 'deno.exe' } | Select-Object -First 1
        if ($e) {
          [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $Root 'deno.exe'), $true)
        }
      } finally { $z.Dispose() }
    }
  }
  Write-Host ""
}

# ---------- PATH (default: always) ----------
if (-not $SkipPath) {
  Write-Step "adding downterm to user PATH ..."
  $install = Join-Path $Root 'install-path.ps1'
  if (-not (Test-Path $install)) {
    Write-Bad "install-path.ps1 missing"
    exit 1
  }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $install
  if ($LASTEXITCODE -ne 0) {
    Write-Bad "PATH install failed"
    exit 1
  }
  # mark first-run so menu does not nag again
  Set-Content -Path (Join-Path $Root '.downterm_path_ok') -Value 'installed' -Encoding ASCII
} else {
  Write-Warn "skipped PATH (-SkipPath). Run setup.bat again without flags, or: download.bat --install"
}

Write-Host ""
Write-Ok "setup complete"
Write-Host ""
Write-Host "  Next:" -ForegroundColor DarkGray
Write-Host "    1. Close this window"
Write-Host "    2. Open a NEW PowerShell or cmd"
Write-Host "    3. Type:  downterm"
Write-Host ""
Write-Host "  Manual PATH only (anytime):" -ForegroundColor DarkGray
Write-Host "    setup.bat -PathOnly"
Write-Host "    download.bat --install"
Write-Host "    menu → 7"
Write-Host ""
exit 0
