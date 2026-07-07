<#
.SYNOPSIS
    Installs Scoop (if needed) and a predefined list of applications via Scoop.

.DESCRIPTION
    Ensures Scoop package manager is installed, adds common buckets, then loops
    through an array of Scoop app names and installs each one, printing
    colorful status messages along the way.

.NOTES
    Scoop is designed to run WITHOUT admin rights. Run this from a normal
    (non-elevated) PowerShell session. If your Execution Policy blocks
    scripts, run:  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#>

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "          Scoop Bulk Application Installer         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Step 1: Make sure Scoop itself is installed
# ---------------------------------------------------------------------------
if (-not (Get-Command scoop -ErrorAction SilentlyContinue))
{
  Write-Host "Scoop not found. Installing Scoop now..." -ForegroundColor Yellow

  try
  {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -ErrorAction Stop
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

    if (Get-Command scoop -ErrorAction SilentlyContinue)
    {
      Write-Host "SUCCESS: Scoop installed successfully." -ForegroundColor Green
    } else
    {
      Write-Host "ERROR: Scoop installation did not complete correctly." -ForegroundColor Red
      exit 1
    }
  } catch
  {
    Write-Host "ERROR: Failed to install Scoop -> $($_.Exception.Message)" -ForegroundColor Red
    exit 1
  }
} else
{
  Write-Host "Scoop is already installed. Skipping installer." -ForegroundColor Green
}

Write-Host ""

# ---------------------------------------------------------------------------
# Step 2: Add common buckets (extras bucket unlocks most GUI apps)
# ---------------------------------------------------------------------------
$bucketList = @(
  "extras",
  "versions"
)

Write-Host "Adding buckets..." -ForegroundColor Cyan
foreach ($bucket in $bucketList)
{
  try
  {
    scoop bucket add $bucket 2>$null
    Write-Host "  - Bucket ready: $bucket" -ForegroundColor Green
  } catch
  {
    Write-Host "  - WARNING: Could not add bucket '$bucket' -> $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

Write-Host ""

# ---------------------------------------------------------------------------
# 1. Array of apps to install (Scoop app names)
#    Search available apps with: scoop search <name>
# ---------------------------------------------------------------------------
$appList = @(
  "tree-sitter",
  "scoop-completion",
  "scoop-search",
  "opencode",
  "zip",
  "unzip",
  "touch",
  "gsudo",
  "mpv"
)

Write-Host "Total apps queued for installation: $($appList.Count)" -ForegroundColor Yellow
Write-Host ""

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
    scoop install $app

    if ($LASTEXITCODE -eq 0)
    {
      Write-Host "SUCCESS: $app installed successfully." -ForegroundColor Green
      $successList += $app
    } else
    {
      Write-Host "WARNING: $app returned exit code $LASTEXITCODE (it may already be installed)." -ForegroundColor Yellow
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
Write-Host "Failed / Already Installed ($($failList.Count)):" -ForegroundColor Red
foreach ($item in $failList)
{
  Write-Host "  - $item" -ForegroundColor Red
}

Write-Host ""
Write-Host "All done! Run 'scoop list' to see everything installed." -ForegroundColor Magenta
