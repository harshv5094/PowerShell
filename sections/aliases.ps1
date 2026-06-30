Set-Alias -Name grep -Value findstr
Set-Alias -Name cpa -Value Copy-ItemAll
Set-Alias -Name wgi -Value Install-WingetPackage
Set-Alias -Name wgr -Value Remove-WingetPackage

if (Get-Command nvim -ErrorAction SilentlyContinue)
{
  Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'
  Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
}

function Install-PosixPkgs()
{
  winget install --id="BrechtSanders.WinLibs.POSIX.UCRT" -e
}

if (Get-Command eza -ErrorAction SilentlyContinue)
{
  function ezaList
  { eza -lg  --icons @args
  }
  function ezaListHidden
  { eza -lga --icons @args
  }
  Set-Alias -Name ll -Value ezaList -Option AllScope
  Set-Alias -Name lla -Value ezaListHidden -Option AllScope
}

if (Get-Command lazygit -ErrorAction SilentlyContinue)
{
  Set-Alias -Name lg -Value lazygit
}

if (Test-Path "$env:LOCALAPPDATA\mnvim")
{
  function mnvim
  {
    $previous = $env:NVIM_APPNAME
    $env:NVIM_APPNAME = "mnvim"
    try
    {
      nvim @args
    } finally
    {
      $env:NVIM_APPNAME = $previous
    }
  }
}
