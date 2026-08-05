# downterm GUI — minimal dark window (Windows)
# double-click friendly: paste is automatic, download is one click

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Get-ClipUrl {
  try {
    $t = [System.Windows.Forms.Clipboard]::GetText()
    if ($t -match 'https?://\S+') { return $Matches[0].TrimEnd(').,]>"''') }
  } catch {}
  return ''
}

function Invoke-Download {
  param($Url, $Mode, $Quality, $Subs, $Force, $Sponsor, $Output)
  if (-not (Test-Path (Join-Path $Root 'yt-dlp.exe'))) {
    [System.Windows.Forms.MessageBox]::Show(
      "yt-dlp.exe missing. Open Terminal mode and press Setup, or run download.bat --setup",
      'downterm', 'OK', 'Warning') | Out-Null
    return $false
  }
  $ff = ''
  if (Test-Path (Join-Path $Root 'ffmpeg.exe')) { $ff = '.\ffmpeg.exe' }
  $subsN = if ($Subs) { '1' } else { '0' }
  $forceN = if ($Force) { '1' } else { '0' }
  $sponN = if ($Sponsor) { '1' } else { '0' }
  $out = if ($Output) { $Output } else { '' }

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = 'powershell.exe'
  $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$Root\filter.ps1`" `"$Url`" `"$ff`" `"$Mode`" `"$Quality`" `"$out`" `"$subsN`" `"$forceN`" `"$sponN`""
  $psi.WorkingDirectory = $Root
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardError = $true
  $psi.RedirectStandardOutput = $true
  $p = [System.Diagnostics.Process]::Start($psi)
  $err = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if ($p.ExitCode -eq 0) {
    try {
      $hist = Join-Path $Root '.downterm_history'
      Add-Content -Path $hist -Value $Url
      Set-Content -Path (Join-Path $Root '.downterm_last.txt') -Value $Url
    } catch {}
    return $true
  }
  $snippet = ($err -split "`n" | Select-Object -Last 8) -join "`n"
  [System.Windows.Forms.MessageBox]::Show(
    "Download finished with errors.`n`n$snippet",
    'downterm', 'OK', 'Error') | Out-Null
  return $false
}

# --- form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = 'downterm'
$form.Size = New-Object System.Drawing.Size(460, 420)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(11, 14, 20)
$form.ForeColor = [System.Drawing.Color]::FromArgb(235, 240, 248)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$accent = [System.Drawing.Color]::FromArgb(160, 190, 235)
$muted = [System.Drawing.Color]::FromArgb(130, 140, 155)
$panel = [System.Drawing.Color]::FromArgb(18, 22, 32)
$line = [System.Drawing.Color]::FromArgb(40, 48, 62)

function Style-Box($c) {
  $c.BackColor = $panel
  $c.ForeColor = $form.ForeColor
  if ($c -is [System.Windows.Forms.TextBox]) {
    $c.BorderStyle = 'FixedSingle'
  } elseif ($c -is [System.Windows.Forms.Button] -or $c -is [System.Windows.Forms.ComboBox]) {
    $c.FlatStyle = 'Flat'
  }
}

$y = 18
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = 'downterm'
$lblTitle.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 16)
$lblTitle.ForeColor = $accent
$lblTitle.Location = New-Object System.Drawing.Point(20, $y)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = 'quiet downloads · one click'
$lblSub.ForeColor = $muted
$lblSub.Location = New-Object System.Drawing.Point(130, ($y + 8))
$lblSub.AutoSize = $true
$form.Controls.Add($lblSub)

$y = 56
$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = 'link'
$lblUrl.ForeColor = $muted
$lblUrl.Location = New-Object System.Drawing.Point(20, $y)
$lblUrl.AutoSize = $true
$form.Controls.Add($lblUrl)

$txtUrl = New-Object System.Windows.Forms.TextBox
$txtUrl.Location = New-Object System.Drawing.Point(20, ($y + 22))
$txtUrl.Size = New-Object System.Drawing.Size(320, 28)
Style-Box $txtUrl
$txtUrl.Text = Get-ClipUrl
$form.Controls.Add($txtUrl)

$btnClip = New-Object System.Windows.Forms.Button
$btnClip.Text = 'paste'
$btnClip.Location = New-Object System.Drawing.Point(350, ($y + 20))
$btnClip.Size = New-Object System.Drawing.Size(70, 30)
$btnClip.FlatStyle = 'Flat'
$btnClip.BackColor = $panel
$btnClip.ForeColor = $accent
$btnClip.FlatAppearance.BorderColor = $line
$btnClip.Add_Click({ $txtUrl.Text = Get-ClipUrl })
$form.Controls.Add($btnClip)

$y = 120
$grpType = New-Object System.Windows.Forms.GroupBox
$grpType.Text = 'type'
$grpType.ForeColor = $muted
$grpType.Location = New-Object System.Drawing.Point(20, $y)
$grpType.Size = New-Object System.Drawing.Size(200, 70)
$grpType.BackColor = $form.BackColor
$form.Controls.Add($grpType)

$rbVideo = New-Object System.Windows.Forms.RadioButton
$rbVideo.Text = 'video'
$rbVideo.Location = New-Object System.Drawing.Point(16, 28)
$rbVideo.AutoSize = $true
$rbVideo.Checked = $true
$rbVideo.ForeColor = $form.ForeColor
$grpType.Controls.Add($rbVideo)

$rbAudio = New-Object System.Windows.Forms.RadioButton
$rbAudio.Text = 'audio'
$rbAudio.Location = New-Object System.Drawing.Point(100, 28)
$rbAudio.AutoSize = $true
$rbAudio.ForeColor = $form.ForeColor
$grpType.Controls.Add($rbAudio)

$lblQ = New-Object System.Windows.Forms.Label
$lblQ.Text = 'quality'
$lblQ.ForeColor = $muted
$lblQ.Location = New-Object System.Drawing.Point(240, $y)
$lblQ.AutoSize = $true
$form.Controls.Add($lblQ)

$cmbQ = New-Object System.Windows.Forms.ComboBox
$cmbQ.Location = New-Object System.Drawing.Point(240, ($y + 28))
$cmbQ.Size = New-Object System.Drawing.Size(180, 28)
$cmbQ.DropDownStyle = 'DropDownList'
$cmbQ.FlatStyle = 'Flat'
$cmbQ.BackColor = $panel
$cmbQ.ForeColor = $form.ForeColor
[void]$cmbQ.Items.AddRange(@('best', '2160 (4K)', '1440', '1080', '720', '480'))
$cmbQ.SelectedIndex = 0
$form.Controls.Add($cmbQ)

$y = 210
$chkSubs = New-Object System.Windows.Forms.CheckBox
$chkSubs.Text = 'English subs'
$chkSubs.Location = New-Object System.Drawing.Point(24, $y)
$chkSubs.AutoSize = $true
$chkSubs.ForeColor = $form.ForeColor
$form.Controls.Add($chkSubs)

$chkSponsor = New-Object System.Windows.Forms.CheckBox
$chkSponsor.Text = 'SponsorBlock'
$chkSponsor.Location = New-Object System.Drawing.Point(160, $y)
$chkSponsor.AutoSize = $true
$chkSponsor.ForeColor = $form.ForeColor
$form.Controls.Add($chkSponsor)

$chkForce = New-Object System.Windows.Forms.CheckBox
$chkForce.Text = 'overwrite'
$chkForce.Location = New-Object System.Drawing.Point(310, $y)
$chkForce.AutoSize = $true
$chkForce.ForeColor = $form.ForeColor
$form.Controls.Add($chkForce)

$y = 250
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = 'ready'
$lblStatus.ForeColor = $muted
$lblStatus.Location = New-Object System.Drawing.Point(24, $y)
$lblStatus.Size = New-Object System.Drawing.Size(400, 24)
$form.Controls.Add($lblStatus)

$y = 290
$btnGo = New-Object System.Windows.Forms.Button
$btnGo.Text = 'download'
$btnGo.Location = New-Object System.Drawing.Point(20, $y)
$btnGo.Size = New-Object System.Drawing.Size(200, 40)
$btnGo.FlatStyle = 'Flat'
$btnGo.BackColor = $accent
$btnGo.ForeColor = [System.Drawing.Color]::FromArgb(11, 14, 20)
$btnGo.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 11)
$btnGo.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnGo)

$btnFolder = New-Object System.Windows.Forms.Button
$btnFolder.Text = 'open folder'
$btnFolder.Location = New-Object System.Drawing.Point(236, $y)
$btnFolder.Size = New-Object System.Drawing.Size(100, 40)
$btnFolder.FlatStyle = 'Flat'
$btnFolder.BackColor = $panel
$btnFolder.ForeColor = $form.ForeColor
$btnFolder.FlatAppearance.BorderColor = $line
$btnFolder.Add_Click({ Start-Process explorer.exe $Root })
$form.Controls.Add($btnFolder)

$btnTerm = New-Object System.Windows.Forms.Button
$btnTerm.Text = 'terminal'
$btnTerm.Location = New-Object System.Drawing.Point(348, $y)
$btnTerm.Size = New-Object System.Drawing.Size(72, 40)
$btnTerm.FlatStyle = 'Flat'
$btnTerm.BackColor = $panel
$btnTerm.ForeColor = $muted
$btnTerm.FlatAppearance.BorderColor = $line
$btnTerm.Add_Click({
  Start-Process -FilePath 'cmd.exe' -ArgumentList "/k `"$Root\download.bat`" --tui" -WorkingDirectory $Root
})
$form.Controls.Add($btnTerm)

$btnGo.Add_Click({
  $url = $txtUrl.Text.Trim()
  if ($url -notmatch '^https?://') {
    [System.Windows.Forms.MessageBox]::Show('Need a link (http/https). Click paste.', 'downterm', 'OK', 'Information') | Out-Null
    return
  }
  $mode = if ($rbAudio.Checked) { 'audio' } else { 'video' }
  $qraw = [string]$cmbQ.SelectedItem
  $quality = switch -Regex ($qraw) {
    '^2160' { '2160' }
    '^1440' { '1440' }
    '^1080' { '1080' }
    '^720'  { '720' }
    '^480'  { '480' }
    default { 'best' }
  }
  if ($mode -eq 'audio') { $quality = 'best' }
  $btnGo.Enabled = $false
  $lblStatus.Text = 'downloading…'
  $lblStatus.ForeColor = $accent
  $form.Refresh()
  $ok = Invoke-Download -Url $url -Mode $mode -Quality $quality `
    -Subs $chkSubs.Checked -Force $chkForce.Checked -Sponsor $chkSponsor.Checked -Output ''
  if ($ok) {
    $lblStatus.Text = 'saved · next to downterm'
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(141, 198, 156)
  } else {
    $lblStatus.Text = 'failed · see message'
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(230, 120, 140)
  }
  $btnGo.Enabled = $true
})

# auto-refresh clipboard when window activates
$form.Add_Activated({
  if ([string]::IsNullOrWhiteSpace($txtUrl.Text)) {
    $txtUrl.Text = Get-ClipUrl
  }
})

[void]$form.ShowDialog()
