# Module Installation #
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

# Utility function (Similar to linux) #
function which ($command)
{
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function whereis($command)
{
  Get-Command $command | Select-Object -ExpandProperty Source
}

# My custom aliases function #
function Copy-ItemAll
{
  Copy-Item -Recurse -Force @args
}

# My Aliases #
Set-Alias -Name grep -Value findstr
Set-Alias -Name cpa -Value Copy-ItemAll

if (Get-Command zoxide -ErrorAction SilentlyContinue)
{
  Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}

if (Get-Command starship -ErrorAction SilentlyContinue)
{
  Invoke-Expression (&starship init powershell)
}

if (Get-Command eza -ErrorAction SilentlyContinue)
{
  function ezaList
  { eza -l -g --header --icons @args 
  }
  function ezaListHidden
  { eza -l -g -a --header --icons @args 
  }
  Set-Alias -Name ll -Value ezaList -Option AllScope
  Set-Alias -Name lla -Value ezaListHidden -Option AllScope
}

if (Get-Command lazygit -ErrorAction SilentlyContinue)
{
  Set-Alias -Name lg -Value lazygit
}

if (Get-Command bat -ErrorAction SilentlyContinue)
{
  Set-Alias -Name cat -Value bat
}
