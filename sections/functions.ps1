# Which command like linux
function which ($command)
{
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Whereis function like linux
function whereis($command)
{
  Get-Command $command | Select-Object -ExpandProperty Source
}

# A function to listen music
function listen()
{
  if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Command ffplay -ErrorAction SilentlyContinue))
  {
    $file = Get-ChildItem -Path "$HOME\Music" -Recurse -Filter "*.mp3" |
      Select-Object -ExpandProperty FullName | fzf --header='** Select a Song **' --height=60% --prompt="Play > "

    if ($file)
    {
      ffplay -nodisp -autoexit $file
    } else
    {
      Write-Host "No file selected. Exiting...."
    }
  } else
  {
    Write-Host "fzf or ffmpeg not found. Install them first."
  }
}

# A copy function with recurse and force already applied
function Copy-ItemAll
{
  Copy-Item -Recurse -Force @args
}

function Install-WingetPackage ([string]$Query = "")
{
  Write-Host "Loading winget package list..." -ForegroundColor Cyan
  $packages = winget search $Query --accept-source-agreements

  $packages | fzf --multi --height=60% --prompt="Install > " | ForEach-Object {
    $id = ($_ -split '\s{2,}')[1].Trim()
    Write-Host "Installing $id..." -ForegroundColor Cyan
    winget install --id $id --exact --accept-package-agreements --accept-source-agreements
  }
}

function Remove-WingetPackage
{
  Write-Host "Loading installed packages..." -ForegroundColor Cyan
  $packages = winget list --accept-source-agreements

  $packages | fzf --multi --height=60% --prompt="Uninstall > " | ForEach-Object {
    $id = ($_ -split '\s{2,}')[1].Trim()
    Write-Host "Uninstalling $id..." -ForegroundColor Cyan
    winget uninstall --id $id --accept-source-agreements
  }
}
