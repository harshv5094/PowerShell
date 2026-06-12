$musicDirectory = Join-Path $HOME "Music"

if (-not (Test-Path -Path $musicDirectory -PathType Container))
{
  New-Item -ItemType Directory -Path $musicDirectory -Force | Out-Null
}

if (Get-Command yt-dlp -ErrorAction SilentlyContinue)
{
  if ($args.Count -ne 1)
  {
    Write-Host "Usage: ext-mp3 <URL>"
    exit 1
  }

  $url = $args[0]

  yt-dlp -x `
    --audio-format mp3 `
    --audio-quality 0 `
    --convert-thumbnails jpg `
    --ppa "ThumbnailsConvertor+ffmpeg_o:-vf crop='ih:ih'" `
    --embed-thumbnail `
    --embed-metadata `
    --sponsorblock-remove all `
    --parse-metadata "%(title)s:%(title)s" `
    --parse-metadata "%(uploader)s:%(artist)s" `
    --output "$musicDirectory\%(title)s.%(ext)s" `
    $url

  exit 0
} else
{
  Write-Host "yt-dlp not found. Install it first."
  exit 1
}
