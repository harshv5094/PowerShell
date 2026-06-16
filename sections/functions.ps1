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
      Select-Object -ExpandProperty FullName |
      fzf --border-label "** Select Song **"

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

function Install-WingetPackage
{
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string] $Query = "",
    [switch] $Silent,
    [switch] $Force
  )

  # ── Preflight checks ────────────────────────────────────────────────────────
  foreach ($tool in 'winget', 'fzf')
  {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue))
    {
      Write-Error "'$tool' was not found on PATH. Install it and try again."
      return
    }
  }

  # ── Fetch search results ────────────────────────────────────────────────────
  Write-Host "Searching packages$(if ($Query) { " for '$Query'" })…" -ForegroundColor Cyan

  $raw = winget search $Query --accept-source-agreements 2>$null

  if ($LASTEXITCODE -ne 0 -or -not $raw)
  {
    Write-Error "winget search failed. Make sure the App Installer is up to date."
    return
  }

  # Drop header and divider lines winget emits
  $packages = $raw | Where-Object {
    $_ -match '\S' -and
    $_ -notmatch '^-+' -and
    $_ -notmatch '^Name\s+Id'
  }

  if (-not $packages)
  {
    Write-Host "No packages found$(if ($Query) { " for '$Query'" })." -ForegroundColor Yellow
    return
  }

  # ── Launch fzf ──────────────────────────────────────────────────────────────
  $fzfArgs = @(
    '--multi'
    '--cycle'
    '--height=70%'
    '--layout=reverse'
    '--border=rounded'
    '--prompt=  Install > '
    '--marker=✓ '
    '--pointer=▶ '
    '--header=TAB: select/deselect  |  ENTER: install  |  ESC: cancel'
    '--header-first'
    '--color=header:italic:cyan,prompt:bright-green,marker:green,pointer:bright-cyan'
    '--preview-window=down:3:wrap'
  )

  $selected = $packages | fzf @fzfArgs

  if (-not $selected)
  {
    Write-Host "No packages selected. Exiting." -ForegroundColor Yellow
    return
  }

  # ── Parse winget IDs ────────────────────────────────────────────────────────
  $ids = foreach ($line in $selected)
  {
    $tokens = $line -split '\s{2,}'
    if ($tokens.Count -ge 2)
    { $tokens[1].Trim() 
    }
  }

  if (-not $ids)
  {
    Write-Warning "Could not parse package IDs from the selection. Aborting."
    return
  }

  # ── Confirm & install ───────────────────────────────────────────────────────
  Write-Host "`nPackages queued for installation:" -ForegroundColor Cyan
  $ids | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
  Write-Host ""

  foreach ($id in $ids)
  {
    if ($PSCmdlet.ShouldProcess($id, 'Install'))
    {
      Write-Host "Installing: " -NoNewline -ForegroundColor Cyan
      Write-Host $id -ForegroundColor Yellow

      $installArgs = @(
        'install'
        '--id',     $id
        '--exact'
        '--accept-package-agreements'
        '--accept-source-agreements'
      )
      if ($Silent)
      { $installArgs += '--silent' 
      }
      if ($Force)
      { $installArgs += '--force' 
      }

      winget @installArgs

      if ($LASTEXITCODE -eq 0)
      {
        Write-Host "  ✔ Installed $id" -ForegroundColor Green
      } else
      {
        Write-Warning "  ✘ winget exited with code $LASTEXITCODE for '$id'."
      }

      Write-Host ""
    }
  }

  Write-Host "Done." -ForegroundColor Green
}


# Installing winget packages using fzf
function Remove-WingetPackage
{
  param(
    [string]$Query = ""
  )

  $selected = winget list $Query |
    Select-Object -Skip 2 |
    fzf --ansi `
      --prompt "Remove > " `
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
      winget remove --id $id --exact --accept-package-agreements --accept-source-agreements
    }
  }
}

function Remove-WingetPackage
{
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [switch] $Force,
    [switch] $Purge,
    [switch] $Silent
  )

  # ── Preflight checks ────────────────────────────────────────────────────────
  foreach ($tool in 'winget', 'fzf')
  {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue))
    {
      Write-Error "'$tool' was not found on PATH. Install it and try again."
      return
    }
  }

  # ── Fetch installed packages ────────────────────────────────────────────────
  Write-Host "Fetching installed packages…" -ForegroundColor Cyan

  # --accept-source-agreements suppresses the interactive EULA prompt
  $raw = winget list --accept-source-agreements 2>$null

  if ($LASTEXITCODE -ne 0 -or -not $raw)
  {
    Write-Error "winget list failed. Make sure the App Installer is up to date."
    return
  }

  # Drop the decorative header lines (dashes, column names) winget emits
  $packages = $raw | Where-Object {
    $_ -match '\S' -and           # non-blank
    $_ -notmatch '^-+' -and       # not a divider line
    $_ -notmatch '^Name\s+Id'     # not the header row
  }

  if (-not $packages)
  {
    Write-Host "No packages found." -ForegroundColor Yellow
    return
  }

  # ── Launch fzf ──────────────────────────────────────────────────────────────
  $fzfArgs = @(
    '--multi'                              # TAB = toggle selection
    '--cycle'                              # wrap around at list edges
    '--height=70%'
    '--layout=reverse'
    '--border=rounded'
    '--prompt=  Uninstall > '
    '--marker=✓ '
    '--pointer=▶ '
    '--header=TAB: select/deselect  |  ENTER: uninstall  |  ESC: cancel'
    '--header-first'
    '--color=header:italic:cyan,prompt:bright-blue,marker:green,pointer:bright-red'
    '--preview=echo {} | Out-String'       # basic preview; extend as needed
    '--preview-window=down:3:wrap'
  )

  $selected = $packages | fzf @fzfArgs

  if (-not $selected)
  {
    Write-Host "No packages selected. Exiting." -ForegroundColor Yellow
    return
  }

  # ── Parse the winget ID from each selected line ─────────────────────────────
  # winget list columns: Name  Id  Version  Available  Source
  # The Id column is the second whitespace-delimited token.
  $ids = foreach ($line in $selected)
  {
    $tokens = $line -split '\s{2,}'   # winget uses 2+ spaces as column separator
    if ($tokens.Count -ge 2)
    { $tokens[1].Trim() 
    }
  }

  if (-not $ids)
  {
    Write-Warning "Could not parse package IDs from the selection. Aborting."
    return
  }

  # ── Confirm & uninstall ─────────────────────────────────────────────────────
  Write-Host "`nPackages queued for removal:" -ForegroundColor Cyan
  $ids | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
  Write-Host ""

  foreach ($id in $ids)
  {
    if ($PSCmdlet.ShouldProcess($id, 'Uninstall'))
    {
      Write-Host "Uninstalling: " -NoNewline -ForegroundColor Cyan
      Write-Host $id -ForegroundColor Yellow

      $uninstallArgs = @('uninstall', '--id', $id, '--accept-source-agreements')
      if ($Force)
      { $uninstallArgs += '--force' 
      }
      if ($Purge)
      { $uninstallArgs += '--purge' 
      }
      if ($Silent)
      { $uninstallArgs += '--silent' 
      }

      winget @uninstallArgs

      if ($LASTEXITCODE -eq 0)
      {
        Write-Host "  ✔ Removed $id" -ForegroundColor Green
      } else
      {
        Write-Warning "  ✘ winget exited with code $LASTEXITCODE for '$id'."
      }

      Write-Host ""
    }
  }
  Write-Host "Done." -ForegroundColor Green
}
