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

# A copy function with recurse and force already applied
function Copy-ItemAll
{
  Copy-Item -Recurse -Force @args
}

# Installing winget packages using fzf
function Install-WingetPackage
{
  param(
    [string]$Query = ""
  )

  $selected = winget search $Query --accept-source-agreements |
    Select-Object -Skip 2 |
    fzf --ansi `
      --prompt "Install > " `
      --header "[TAB] multi-select  [ENTER] install  [ESC] cancel" `
      --multi `
      --height "60%" `
      --layout "reverse" `
      --border "rounded" `

  if (-not $selected)
  {
    Write-Host "No package selected." -ForegroundColor Yellow
    return
  }

  foreach ($line in $selected)
  {
    $id = ($line -split '\s{2,}')[1]
    if ($id)
    {
      Write-Host "Installing $id..." -ForegroundColor Cyan
      winget install --id $id --exact --accept-package-agreements --accept-source-agreements
    }
  }
}
