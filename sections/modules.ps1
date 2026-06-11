if (Get-Module -ListAvailable -Name PSReadLine)
{
  Import-Module PSReadLine
  Set-PSReadLineOption -EditMode Emacs
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
  Set-PSReadLineOption -PredictionSource History
} else
{
  Write-Host "PSReadLine not found. Installing..." -ForegroundColor Yellow
  Install-Module -Name PSReadLine -Scope CurrentUser -Force
  Write-Host "PSReadLine installed successfully." -ForegroundColor Green
  Import-Module PSReadLine
  Set-PSReadLineOption -EditMode Emacs
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
  Set-PSReadLineOption -PredictionSource History
}

if (Get-Module -ListAvailable -Name PSFzf)
{
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
} else
{
  Write-Host "PSFzf not found. Installing..." -ForegroundColor Yellow
  Install-Module -Name PSFzf -Scope CurrentUser -Force
  Write-Host "PSFzf installed successfully." -ForegroundColor Green
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
