param(
  [Parameter(Mandatory=$true)][string]$url,
  [string]$ff
)
$ErrorActionPreference = 'SilentlyContinue'

$ytargs = @('-f','bv*+ba/b','--merge-output-format','mp4','-o','%(title)s.%(ext)s','--newline')
if ($ff) { $ytargs += @('--ffmpeg-location',$ff) }
$ytargs += $url

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
  if ($line -match '\[download\]\s+([\d.]+)%') {
    $pct = [double]$matches[1]
    $n = [int][math]::Round(($pct/100)*30)
    $filled = '#' * $n
    $empty  = '-' * (30 - $n)
    [Console]::Error.Write("`r  " + $filled + $empty + "  " + $pct.ToString('0.0') + "%   ")
    $lastBar = $true
  } else {
    if ($lastBar) { [Console]::Error.WriteLine(''); $lastBar = $false }
    if ($line -notmatch '^\s*$') { [Console]::Error.WriteLine($line) }
  }
}
if ($lastBar) { [Console]::Error.WriteLine('') }
$err = $p.StandardError.ReadToEnd()
if ($err) { [Console]::Error.WriteLine($err) }
$p.WaitForExit()
exit $p.ExitCode
