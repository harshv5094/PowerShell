#Requires -Version 5.1
<#
.SYNOPSIS
    Fuzzy-search your local anime library with fzf and play the pick in mpv.
    Falls back to an "online search" hook if nothing local matches.

.DESCRIPTION
    - Recursively scans $LibraryPaths for video files.
    - Parses "Show Name" + "Episode" out of common filename patterns.
    - Feeds a clean "Show Name - EpXX" list into fzf (with a live mpv-thumbnail-free
      preview showing the full path).
    - Launches mpv on whatever you pick.
    - If you don't find what you want locally, pick the "Search online..." entry
      and it calls Search-AnimeOnline, which is a STUB you fill in yourself with
      whatever legal source/API/self-hosted server you use. This script does not
      ship with, or hardcode, any streaming/scraping backend.

.NOTES
    Requires: fzf, mpv on PATH.
        winget install junegunn.fzf
        winget install mpv-player.mpv
#>

# ---------------------------------------------------------------------------
# CONFIG - edit these for your setup
# ---------------------------------------------------------------------------
$LibraryPaths = @(
  "$HOME\Videos\Anime",
  "D:\Anime"
) | Where-Object { Test-Path $_ }

$VideoExtensions = @('.mkv', '.mp4', '.avi', '.webm', '.mov', '.m2ts')

$MpvArgs = @('--force-window=yes')   # add your usual mpv flags here, e.g. '--fullscreen'

$OnlineSearchEntry = '🌐  Search online...'

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
function Assert-CommandExists
{
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue))
  {
    Write-Error "'$Name' not found on PATH. Please install it first."
    exit 1
  }
}
Assert-CommandExists 'fzf'
Assert-CommandExists 'mpv'

if (-not $LibraryPaths -or $LibraryPaths.Count -eq 0)
{
  Write-Warning "No configured local library paths exist on disk. Only the online search entry will be shown."
}

# ---------------------------------------------------------------------------
# Filename parsing
# ---------------------------------------------------------------------------
function ConvertTo-AnimeInfo
{
  <#
        Tries a few common release-naming patterns and returns
        [PSCustomObject]@{ ShowName; Episode; Season }
        Falls back to the raw filename if nothing matches.
    #>
  param([string]$FileName)

  $name = [System.IO.Path]::GetFileNameWithoutExtension($FileName)

  # Strip a leading [ReleaseGroup] tag
  $name = $name -replace '^\[[^\]]+\]\s*', ''
  # Strip trailing [tags] / (tags), e.g. [1080p][ABCD1234]
  $name = $name -replace '(\[[^\]]*\]|\([^\)]*\))\s*$', ''
  $name = $name.Trim()

  # Pattern 1: Show.Name.S01E12  or Show Name S01E12
  if ($name -match '^(?<show>.+?)[\.\s_]+[Ss](?<season>\d{1,2})[Ee](?<ep>\d{1,3})')
  {
    return [PSCustomObject]@{
      ShowName = ($matches.show -replace '[\.\_]', ' ').Trim()
      Episode  = [int]$matches.ep
      Season   = [int]$matches.season
    }
  }

  # Pattern 2: Show Name - 12  (classic fansub style, optional decimal for specials e.g. 12.5)
  if ($name -match '^(?<show>.+?)[\s\-_]+-?\s*(?<ep>\d{1,3}(\.\d)?)\s*(\[.*\])?$')
  {
    return [PSCustomObject]@{
      ShowName = ($matches.show -replace '[\.\_]', ' ').Trim(' ', '-')
      Episode  = $matches.ep
      Season   = 1
    }
  }

  # Pattern 3: Show Name Episode 12
  if ($name -match '^(?<show>.+?)\s+[Ee]pisode\s*(?<ep>\d{1,3})')
  {
    return [PSCustomObject]@{
      ShowName = ($matches.show -replace '[\.\_]', ' ').Trim()
      Episode  = [int]$matches.ep
      Season   = 1
    }
  }

  # Fallback: no reliable parse, just show the cleaned filename
  return [PSCustomObject]@{
    ShowName = ($name -replace '[\.\_]', ' ').Trim()
    Episode  = $null
    Season   = $null
  }
}

# ---------------------------------------------------------------------------
# Local library scan
# ---------------------------------------------------------------------------
function Get-LocalEpisodes
{
  param([string[]]$Paths)

  $files = foreach ($p in $Paths)
  {
    Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $VideoExtensions -contains $_.Extension.ToLower() }
  }

  foreach ($f in $files)
  {
    $info = ConvertTo-AnimeInfo -FileName $f.Name
    $label = if ($info.Episode)
    {
      "{0} - Ep{1}" -f $info.ShowName, $info.Episode
    } else
    {
      $info.ShowName
    }
    [PSCustomObject]@{
      Display = $label
      Path    = $f.FullName
    }
  }
}

# ---------------------------------------------------------------------------
# Online search STUB - implement this yourself
# ---------------------------------------------------------------------------
function Search-AnimeOnline
{
  <#
        Wire this up to whatever legal source you actually use: a paid
        streaming API you have access to, a self-hosted Jellyfin/Plex
        instance, your own indexer, etc. It must return objects shaped like:
            [PSCustomObject]@{ Display = 'Show - EpXX'; Path = 'https://...' }
        'Path' can be any URL mpv can open (direct file, m3u8, etc).
    #>
  param([string]$Query)

  Write-Warning "Search-AnimeOnline is not implemented. Edit this function in the script to point at your own source."
  return @()
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$episodes = @()
if ($LibraryPaths)
{
  $episodes = Get-LocalEpisodes -Paths $LibraryPaths | Sort-Object Display
}

$menuItems = @($episodes.Display) + $OnlineSearchEntry
$lookup = @{}
foreach ($e in $episodes)
{
  # handle duplicate labels by keeping the first, later ones get a suffix
  if ($lookup.ContainsKey($e.Display))
  {
    $suffix = 2
    $newKey = "$($e.Display) ($suffix)"
    while ($lookup.ContainsKey($newKey))
    { $suffix++; $newKey = "$($e.Display) ($suffix)" 
    }
    $lookup[$newKey] = $e.Path
    $menuItems += $newKey
  } else
  {
    $lookup[$e.Display] = $e.Path
  }
}

$selection = $menuItems | fzf --prompt="Anime > " --height=90% --border --reverse `
  --preview 'echo {}' --preview-window=up:1:hidden

if (-not $selection)
{
  Write-Host "Nothing selected." -ForegroundColor Yellow
  exit 0
}

$targetPath = $null

if ($selection -eq $OnlineSearchEntry)
{
  $query = Read-Host "Search query"
  $onlineResults = Search-AnimeOnline -Query $query
  if (-not $onlineResults -or $onlineResults.Count -eq 0)
  {
    Write-Host "No online results (or feature not implemented yet)." -ForegroundColor Yellow
    exit 0
  }
  $onlineLookup = @{}
  foreach ($r in $onlineResults)
  { $onlineLookup[$r.Display] = $r.Path 
  }

  $onlineSelection = $onlineResults.Display | fzf --prompt="Online > " --height=90% --border --reverse
  if (-not $onlineSelection)
  { exit 0 
  }
  $targetPath = $onlineLookup[$onlineSelection]
} else
{
  $targetPath = $lookup[$selection]
}

if (-not $targetPath)
{
  Write-Error "Could not resolve a path for the selection."
  exit 1
}

Write-Host "Playing: $targetPath" -ForegroundColor Cyan
& mpv @MpvArgs $targetPath
