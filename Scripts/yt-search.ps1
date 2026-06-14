#!/usr/bin/env pwsh
# SCRIPT NAME: yt-search
# AUTHOR: Harsh Vyapari (@harshv5094)

# Checking for dependencies
$dependencyList = @("yt-dlp", "fzf", "mpv")

foreach ($app in $dependencyList)
{
  if (-not (Get-Command $app -ErrorAction SilentlyContinue))
  {
    Write-Host "$app not found. Install it first."
    exit 1
  }
}

Write-Host @'
__   _______   _____                     _     
\ \ / /_   _| /  ___|                   | |    
 \ V /  | |   \ `--.  ___  __ _ _ __ ___| |__  
  \ /   | |    `--. \/ _ \/ _` | '__/ __| '_ \ 
  | |   | |   /\__/ /  __/ (_| | | | (__| | | |
  \_/   \_/   \____/ \___|\__,_|_|  \___|_| |_|
'@

# Function to fetch search results
function Search-YouTube
{
  param([string]$Query)
  yt-dlp "ytsearch6:$Query" `
    --flat-playlist `
    --print "%(id)s|%(title)s|%(channel)s|%(duration_string)s" `
    --playlist-end 6 `
    --skip-download `
    --quiet
}

if ($args.Count -eq 0)
{
  Write-Host "Usage: yt-search <query>"
  exit 1
}

$query = $args -join " "
Write-Host "Searching for: $query..."

# Fetch results from YouTube
$results = Search-YouTube -Query $query

if (-not $results)
{
  Write-Host "No results found"
  exit 1
}

$selected = $results | fzf `
  --delimiter '|' `
  --with-nth 2 `
  --preview 'powershell -NoProfile -Command "Write-Host \"URL: https://youtube.com/watch?v={1}\"; Write-Host \"Title: {2}\"; Write-Host \"Channel: {3}\"; Write-Host \"Duration: {4}\""' `
  --preview-window 'bottom' `
  --height '80%' `
  --layout reverse `
  --header 'Select video to play (Ctrl-C to cancel)'

if ($selected)
{
  $parts     = $selected -split '\|'
  $videoId   = $parts[0]
  $videoTitle = $parts[1]
  $videoUrl  = "https://youtube.com/watch?v=$videoId"

  Write-Host "Playing: $videoTitle"

  # Save to history file
  $historyFile = Join-Path $HOME ".ytsearch.txt"
  if (-not (Test-Path $historyFile))
  {
    New-Item -ItemType File -Path $historyFile | Out-Null
  }

  $existingContent = Get-Content $historyFile -ErrorAction SilentlyContinue
  if (-not ($existingContent -match [regex]::Escape($videoTitle)))
  {
    Add-Content -Path $historyFile -Value "$videoTitle - $videoUrl"
  }

  mpv --window-minimized=yes $videoUrl
} else
{
  Write-Host "Not selected, exiting..."
  exit 0
}
