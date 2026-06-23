
# --- Step 1: Check if Scoop is installed ---
$scoopInstalled = Get-Command scoop -ErrorAction SilentlyContinue

if (-not $scoopInstalled)
{
  Write-Host "Scoop is not installed. Installing Scoop now..." -ForegroundColor Yellow

  try
  {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  } catch
  {
    Write-Host "Failed to install Scoop: $_" -ForegroundColor Red
    exit 1
  }

  # Re-check after installation attempt
  $scoopInstalled = Get-Command scoop -ErrorAction SilentlyContinue
  if (-not $scoopInstalled)
  {
    Write-Host "Scoop installation could not be verified. Exiting." -ForegroundColor Red
    exit 1
  }

  Write-Host "Scoop installed successfully." -ForegroundColor Green
} else
{
  Write-Host "Scoop is already installed." -ForegroundColor Green
}


# --- Step 1b: Add the 'extras' bucket ---
$bucketList = scoop bucket list
if ($bucketList -notmatch "extras")
{
  Write-Host "Adding 'extras' bucket..." -ForegroundColor Yellow
  scoop bucket add extras
} else
{
  Write-Host "'extras' bucket already added." -ForegroundColor Green
}

# --- Step 2: Base list of packages ---
$packages = @(
  "7zip",
  "mpv",
  "opencode",
  "gsudo"
  "touch",
  "make"
  "zip",
  "unzip"
)

# --- Step 3: Install each package via a foreach loop ---
Write-Host "`nInstalling base packages..." -ForegroundColor Cyan

foreach ($package in $packages)
{
  Write-Host "Installing $package..." -ForegroundColor Yellow

  scoop install $package

  if ($LASTEXITCODE -ne 0)
  {
    Write-Host "  -> Warning: '$package' may have failed to install (exit code $LASTEXITCODE)." -ForegroundColor Red
  }
}

Write-Host "`nSetup complete!" -ForegroundColor Green
