<#
.SYNOPSIS
    Clears all major Windows cache types, based on the steps described at:
    https://windowsloop.com/clear-all-cache-windows-10/

.DESCRIPTION
    This script clears:
      1. Local Temp cache (%temp%)
      2. Windows Temp cache (C:\Windows\Temp)
      3. Prefetch cache
      4. Windows Update cache (SoftwareDistribution\Download)
      5. Windows Store cache (wsreset)
      6. DNS cache (ipconfig /flushdns)
      7. Icon and Thumbnail cache

    MUST be run with Administrator privileges. The script will self-terminate
    if it is not run elevated.

.NOTES
    Some files may be skipped because they are currently in use by the
    system — this is expected and safe to ignore, per the source article.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# ---------------------------------------------------------------------------
# Enforce Administrator privileges (belt-and-suspenders, in addition to
# the #Requires directive above, in case #Requires is bypassed).
# ---------------------------------------------------------------------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Error "This script must be run as Administrator. Right-click PowerShell and choose 'Run as administrator', then re-run this script."
  exit 1
}

function Write-Section
{
  param([string]$Message)
  Write-Host ""
  Write-Host "==== $Message ====" -ForegroundColor Cyan
}

function Clear-FolderContents
{
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Label = $Path
  )

  if (-not (Test-Path -LiteralPath $Path))
  {
    Write-Host "  Skipping '$Label' - path not found: $Path" -ForegroundColor Yellow
    return
  }

  Write-Host "  Clearing $Label ($Path)..."
  $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue

  $removed = 0
  $skipped = 0

  foreach ($item in $items)
  {
    try
    {
      Remove-Item -LiteralPath $item.FullName -Force -Recurse -ErrorAction Stop
      $removed++
    } catch
    {
      # File/folder in use or access denied - expected, safe to ignore.
      $skipped++
    }
  }

  Write-Host "    Removed: $removed item(s). Skipped (in use / locked): $skipped item(s)." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 1. Clear Local Temp cache (%temp%)
# ---------------------------------------------------------------------------
Write-Section "1. Clearing Local Temp Cache (%temp%)"
Clear-FolderContents -Path $env:TEMP -Label "Local Temp folder"

# ---------------------------------------------------------------------------
# 2. Clear Windows Temp cache (C:\Windows\Temp)
# ---------------------------------------------------------------------------
Write-Section "2. Clearing Windows Temp Cache"
$windowsTemp = Join-Path -Path $env:WINDIR -ChildPath "Temp"
Clear-FolderContents -Path $windowsTemp -Label "Windows Temp folder"

# ---------------------------------------------------------------------------
# 3. Clear Prefetch cache
# ---------------------------------------------------------------------------
Write-Section "3. Clearing Prefetch Cache"
$prefetch = Join-Path -Path $env:WINDIR -ChildPath "Prefetch"
Clear-FolderContents -Path $prefetch -Label "Prefetch folder"

# ---------------------------------------------------------------------------
# 4. Clear Windows Update cache (SoftwareDistribution\Download)
#    Stop the Windows Update service first so files aren't locked, then
#    restart it afterward.
# ---------------------------------------------------------------------------
Write-Section "4. Clearing Windows Update Cache"
$wuauservWasRunning = $false
try
{
  $svc = Get-Service -Name wuauserv -ErrorAction Stop
  if ($svc.Status -eq 'Running')
  {
    $wuauservWasRunning = $true
    Write-Host "  Stopping Windows Update service (wuauserv)..."
    Stop-Service -Name wuauserv -Force -ErrorAction Stop
  }
} catch
{
  Write-Host "  Could not query/stop wuauserv service: $($_.Exception.Message)" -ForegroundColor Yellow
}

$swDistDownload = Join-Path -Path $env:WINDIR -ChildPath "SoftwareDistribution\Download"
Clear-FolderContents -Path $swDistDownload -Label "SoftwareDistribution\Download"

if ($wuauservWasRunning)
{
  Write-Host "  Restarting Windows Update service (wuauserv)..."
  try
  {
    Start-Service -Name wuauserv -ErrorAction Stop
  } catch
  {
    Write-Host "  Could not restart wuauserv service: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# ---------------------------------------------------------------------------
# 5. Clear Windows Store cache (wsreset.exe)
# ---------------------------------------------------------------------------
Write-Section "5. Clearing Windows Store Cache (wsreset)"
try
{
  Start-Process -FilePath "wsreset.exe" -WindowStyle Hidden -Wait -ErrorAction Stop
  Write-Host "  wsreset completed." -ForegroundColor Green
} catch
{
  Write-Host "  wsreset failed or is not available: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 6. Flush DNS cache
# ---------------------------------------------------------------------------
Write-Section "6. Flushing DNS Cache"
try
{
  ipconfig /flushdns | Out-Null
  Write-Host "  DNS cache flushed." -ForegroundColor Green
} catch
{
  Write-Host "  Failed to flush DNS cache: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 7. Clear Icon and Thumbnail cache
#    Requires stopping Explorer temporarily, then restarting it.
# ---------------------------------------------------------------------------
Write-Section "7. Clearing Icon and Thumbnail Cache"
$explorerCachePath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\Explorer"

Write-Host "  Stopping Windows Explorer (taskbar/desktop will briefly disappear)..."
try
{
  Stop-Process -Name explorer -Force -ErrorAction Stop
} catch
{
  Write-Host "  Could not stop explorer.exe: $($_.Exception.Message)" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

if (Test-Path -LiteralPath $explorerCachePath)
{
  $iconFiles = Get-ChildItem -LiteralPath $explorerCachePath -Filter "iconcache*" -Force -ErrorAction SilentlyContinue
  $thumbFiles = Get-ChildItem -LiteralPath $explorerCachePath -Filter "thumbcache_*.db" -Force -ErrorAction SilentlyContinue

  $cacheFiles = @()
  if ($iconFiles)
  { $cacheFiles += $iconFiles 
  }
  if ($thumbFiles)
  { $cacheFiles += $thumbFiles 
  }

  $removed = 0
  $skipped = 0
  foreach ($file in $cacheFiles)
  {
    try
    {
      Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
      $removed++
    } catch
    {
      $skipped++
    }
  }
  Write-Host "  Removed: $removed icon/thumbnail cache file(s). Skipped: $skipped." -ForegroundColor Green
} else
{
  Write-Host "  Explorer cache path not found: $explorerCachePath" -ForegroundColor Yellow
}

Write-Host "  Restarting Windows Explorer..."
Start-Process -FilePath "explorer.exe"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Section "All cache clearing steps completed"
Write-Host "Note: Windows will automatically rebuild these caches as you use your system." -ForegroundColor Cyan
