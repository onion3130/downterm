param(
  [Parameter(Mandatory=$true)][string]$url,
  [string]$ff,
  [string]$mode = "video",
  [string]$quality = "best",
  [string]$output = "",
  [string]$subs = "0",
  [string]$force = "0",
  [string]$sponsor = "0"
)
$ErrorActionPreference = 'SilentlyContinue'

if ($url -notmatch '^https?://') {
  [Console]::Error.WriteLine("")
  [Console]::Error.WriteLine("  ERR-13 - invalid URL  *  must start with http:// or https://")
  exit 13
}

$warnNoFf = (-not $ff) -and (-not (Test-Path '.\ffmpeg.exe')) -and (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue))
if ($warnNoFf -and ($mode -ne "audio")) {
  [Console]::Error.WriteLine("  WARN - ffmpeg not found; some videos will fail to merge. Run 's' to fetch it.")
}

$outTpl = '%(title).200B [%(id)s].%(ext)s'
if ($output) {
  if (-not (Test-Path -LiteralPath $output)) {
    New-Item -ItemType Directory -Path $output -Force | Out-Null
  }
  $outTpl = (Join-Path $output '%(title).200B [%(id)s].%(ext)s')
}

if ($mode -eq "audio") {
  $aq = '0'
  if ($quality -eq "medium") { $aq = '5' }
  elseif ($quality -eq "low") { $aq = '9' }
  $ytargs = @('-x','--audio-format','mp3','--audio-quality',$aq,'-o',$outTpl,'--newline','--no-playlist')
} else {
  $format = switch ($quality) {
    "2160" { 'bv*[ext=mp4][height<=2160]+ba[ext=m4a]/b[ext=mp4]/b' }
    "1440" { 'bv*[ext=mp4][height<=1440]+ba[ext=m4a]/b[ext=mp4]/b' }
    "1080" { 'bv*[ext=mp4][height<=1080]+ba[ext=m4a]/b[ext=mp4]/b' }
    "720"  { 'bv*[ext=mp4][height<=720]+ba[ext=m4a]/b[ext=mp4]/b' }
    "480"  { 'bv*[ext=mp4][height<=480]+ba[ext=m4a]/b[ext=mp4]/b' }
    default { 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b' }
  }
  $ytargs = @('-f',$format,'--merge-output-format','mp4','-o',$outTpl,'--newline')
  if ($url -notmatch 'list=') { $ytargs += '--no-playlist' }
}

if ($ff) { $ytargs += @('--ffmpeg-location',$ff) }
if (Test-Path '.\deno.exe') { $ytargs += @('--js-runtimes','deno:.\deno.exe') }

if ($mode -ne "audio" -and ($subs -eq "1" -or $subs -eq "yes" -or $subs -eq "true")) {
  $ytargs += @('--write-auto-subs','--write-subs','--sub-langs','en.*,en','--embed-subs','--convert-subs','srt')
}

if ($force -eq "1" -or $force -eq "yes" -or $force -eq "true") {
  $ytargs += @('--force-overwrites')
} else {
  $ytargs += @('--no-overwrites','--continue')
}

if ($mode -ne "audio" -and ($sponsor -eq "1" -or $sponsor -eq "yes" -or $sponsor -eq "true")) {
  $ytargs += @('--sponsorblock-remove','sponsor,selfpromo,interaction,intro,outro,preview')
}

$ytargs += $url

$suppressPatterns = @(
  '^\[youtube\]',
  '^\[info\]',
  '^\[Merger\]',
  '^\[Deleting\]',
  '^\[ExtractAudio\]',
  '^\[EmbedSubtitle\]',
  '^\[Metadata\]',
  '^\[SponsorBlock\]',
  '^\[SubtitlesConvertor\]',
  '^\[download\]\s+Destination:',
  'WARNING.*has already been downloaded'
)

function Should-Suppress($line) {
  foreach ($p in $suppressPatterns) {
    if ($line -match $p) { return $true }
  }
  return $false
}

function Get-ErrorCode($line) {
  if ($line -match 'Video unavailable')              { return @{code='ERR-01';msg='video unavailable (private/deleted)'} }
  if ($line -match 'Private video')                   { return @{code='ERR-02';msg='private video - sign in required'} }
  if ($line -match 'Members-only')                    { return @{code='ERR-03';msg='members-only content'} }
  if ($line -match 'geo(?:graphically)? restricted')  { return @{code='ERR-04';msg='geo-restricted in your region'} }
  if ($line -match 'age restricted')                  { return @{code='ERR-05';msg='age-restricted - needs cookies'} }
  if ($line -match 'Sign in to confirm')              { return @{code='ERR-06';msg='bot detection - try again later'} }
  if ($line -match 'No video formats found')          { return @{code='ERR-07';msg='no downloadable formats found'} }
  if ($line -match 'HTTP Error 4')                    { return @{code='ERR-08';msg='HTTP 4xx from server'} }
  if ($line -match 'HTTP Error 5')                    { return @{code='ERR-09';msg='HTTP 5xx from server'} }
  if ($line -match 'Connection (timed out|refused|reset)')  { return @{code='ERR-10';msg='connection failed'} }
  if ($line -match '(ffmpeg.*(not.*(found|installed)|missing)|unable to find.*ffmpeg|could not find.*ffmpeg)') { return @{code='ERR-11';msg='ffmpeg executable missing'} }
  if ($line -match '(deno.*(not.*(found|installed)|missing)|unable to find.*deno|could not find.*deno)') { return @{code='ERR-12';msg='deno runtime missing'} }
  if ($line -match 'Unsupported URL')                 { return @{code='ERR-13';msg='unsupported URL - not a valid video link'} }
  return @{code='ERR-00';msg='unknown error'}
}

$argStr = ($ytargs | ForEach-Object {
  if ($_ -match '\s') { "`"$_`"" } else { $_ }
}) -join ' '

$p = New-Object System.Diagnostics.Process
$p.StartInfo.FileName = '.\yt-dlp.exe'
$p.StartInfo.Arguments = $argStr
$p.StartInfo.UseShellExecute = $false
$p.StartInfo.RedirectStandardOutput = $true
$p.StartInfo.RedirectStandardError = $true
[void]$p.Start()

$lastBar = $false

while (-not $p.StandardOutput.EndOfStream) {
  $line = $p.StandardOutput.ReadLine()
  if ($line -match '\[download\]\s+([\d.]+)%.*?at\s+([\d.]+)([KMG]?)i?B/s.*?ETA\s+(.+)') {
    $pct = [double]$matches[1]
    $speedVal = [double]$matches[2]
    $speedUnit = $matches[3]
    $eta = $matches[4].Trim()
    if ($speedUnit -eq 'M') { $speedMB = $speedVal }
    elseif ($speedUnit -eq 'K') { $speedMB = [math]::Round($speedVal/1024, 2) }
    elseif ($speedUnit -eq 'G') { $speedMB = [math]::Round($speedVal*1024, 2) }
    else { $speedMB = [math]::Round($speedVal/1024/1024, 2) }
    $n = [int][math]::Round(($pct/100)*30)
    $filled = '#' * $n
    $empty  = '-' * (30 - $n)
    $bar = "`r  " + $filled + $empty + "  " + $pct.ToString('0.0') + "%  " + $speedMB.ToString('0.0') + " MB/s  ETA " + $eta + "   "
    [Console]::Error.Write($bar)
    $lastBar = $true
  } elseif ($line -match '\[download\]\s+([\d.]+)%') {
    $pct = [double]$matches[1]
    $n = [int][math]::Round(($pct/100)*30)
    $filled = '#' * $n
    $empty  = '-' * (30 - $n)
    [Console]::Error.Write("`r  " + $filled + $empty + "  " + $pct.ToString('0.0') + "%   ")
    $lastBar = $true
  } elseif (-not (Should-Suppress $line)) {
    if ($line -notmatch '^\s*$') {
      if ($lastBar) { [Console]::Error.WriteLine(''); $lastBar = $false }
      [Console]::Error.WriteLine($line)
    }
  }
}
if ($lastBar) { [Console]::Error.WriteLine('') }

$err = $p.StandardError.ReadToEnd()
if ($err) {
  $errParts = @()
  foreach ($errLine in ($err -split "`n")) {
    if ($errLine -match '^\s*$') { continue }
    if (Should-Suppress $errLine) { continue }
    $mapped = Get-ErrorCode $errLine
    if ($mapped.code -ne 'ERR-00') {
      [Console]::Error.WriteLine("")
      [Console]::Error.WriteLine("  " + $mapped.code + " - " + $mapped.msg + "  *  see github.com/onion3130/downterm/blob/main/docs/ERRORS.md")
    } else {
      $errParts += $errLine
    }
  }
  if ($errParts.Count -gt 0) {
    [Console]::Error.WriteLine("")
    foreach ($ep in $errParts) {
      [Console]::Error.WriteLine("  " + $ep.Trim())
    }
    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("  ERR-00 - unknown error  *  see github.com/onion3130/downterm/blob/main/docs/ERRORS.md")
  }
}

$p.WaitForExit()

if ($p.ExitCode -ne 0) {
  Get-ChildItem -Filter '*.part' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Get-ChildItem -Filter '*.temp' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

exit $p.ExitCode
