Set-Alias -Name grep -Value findstr
Set-Alias -Name cpa -Value Copy-ItemAll
Set-Alias -Name wgi -Value Install-WingetPackage

if (Get-Command eza -ErrorAction SilentlyContinue)
{
  function ezaList
  { eza -l -g --header --icons @args
  }
  function ezaListHidden
  { eza -l -g -a --header --icons @args
  }
  Set-Alias -Name ll -Value ezaList -Option AllScope
  Set-Alias -Name lla -Value ezaListHidden -Option AllScope
}

if (Get-Command lazygit -ErrorAction SilentlyContinue)
{
  Set-Alias -Name lg -Value lazygit
}

if (Get-Command bat -ErrorAction SilentlyContinue)
{
  Set-Alias -Name cat -Value bat
}
