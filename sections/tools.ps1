# Zoxide initialization
if (Get-Command zoxide -ErrorAction SilentlyContinue)
{
  Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}

# Starship initialization
if (Get-Command starship -ErrorAction SilentlyContinue)
{
  Invoke-Expression (&starship init powershell)
}

# FZF options
if (Get-Command fzf -ErrorAction SilentlyContinue)
{
  $env:FZF_DEFAULT_OPTS="
      --reverse
      --border
      --bind 'alt-j:down,alt-k:up'
    "
}
