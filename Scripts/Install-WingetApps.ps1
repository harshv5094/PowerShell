<#
.SYNOPSIS
    Installs a predefined list of applications using winget.

.DESCRIPTION
    Loops through an array of winget package IDs and installs each one,
    printing colorful status messages along the way.

.NOTES
    Run this script from an elevated (Administrator) PowerShell session
    for best results, since some winget installers require admin rights.
#>

# ---------------------------------------------------------------------------
# 1. Array of apps to install (winget package IDs)
#    Find IDs with: winget search <name>
# ---------------------------------------------------------------------------
$appList = @(
  "Git.Git",
  "GitHub.Cli",
  "GnuPG.Gpg4win",
  "GnuPG.GnuPG",
  "Neovim.Neovim",
  "sharkdp.bat",
  "sharkdp.fd",
  "eza-community.eza",
  "junegunn.fzf",
  "cURL.cURL",
  "aristocratos.btop4win",
  "BurntSushi.ripgrep.MSVC",
  "Mozilla.Firefox",
  "7zip.7zip",
  "VideoLAN.VLC",
  "Microsoft.PowerToys",
  "yt-dlp.yt-dlp",
  "yt-dlp.FFmpeg"
)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "        Winget Bulk Application Installer         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total apps queued for installation: $($appList.Count)" -ForegroundColor Yellow
Write-Host ""

# Check winget is available before doing anything else
if (-not (Get-Command winget -ErrorAction SilentlyContinue))
{
  Write-Host "ERROR: winget was not found on this system." -ForegroundColor Red
  Write-Host "Please install 'App Installer' from the Microsoft Store and try again." -ForegroundColor Red
  exit 1
}

# ---------------------------------------------------------------------------
# 2. Foreach loop to install each app
# ---------------------------------------------------------------------------
$successList = @()
$failList    = @()
$counter     = 0

foreach ($app in $appList)
{
  $counter++
  Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
  Write-Host "[$counter/$($appList.Count)] Installing: $app" -ForegroundColor Cyan

  try
  {
    # --accept-package-agreements / --accept-source-agreements avoid interactive prompts
    # -e (--exact) ensures an exact ID match, -h (--silent) suppresses installer UI
    winget install --id $app -e --silent --accept-package-agreements --accept-source-agreements

    if ($LASTEXITCODE -eq 0)
    {
      Write-Host "SUCCESS: $app installed successfully." -ForegroundColor Green
      $successList += $app
    } else
    {
      Write-Host "WARNING: $app returned exit code $LASTEXITCODE." -ForegroundColor Yellow
      $failList += $app
    }
  } catch
  {
    Write-Host "ERROR: Failed to install $app -> $($_.Exception.Message)" -ForegroundColor Red
    $failList += $app
  }

  Write-Host ""
}

# ---------------------------------------------------------------------------
# 3. Summary
# ---------------------------------------------------------------------------
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "                 Installation Summary              " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "Successful ($($successList.Count)):" -ForegroundColor Green
foreach ($item in $successList)
{
  Write-Host "  - $item" -ForegroundColor Green
}

Write-Host ""
Write-Host "Failed ($($failList.Count)):" -ForegroundColor Red
foreach ($item in $failList)
{
  Write-Host "  - $item" -ForegroundColor Red
}

Write-Host ""
Write-Host "All done!" -ForegroundColor Magenta
