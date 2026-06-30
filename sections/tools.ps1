# Scoop Options
if (Get-Command scoop -ErrorAction SilentlyContinue)
{
  Import-Module scoop-completion

  # Setting up scoop search
  . ([ScriptBlock]::Create((& scoop-search --hook | Out-String)))
}

# Starship initialization
if (Get-Command starship -ErrorAction SilentlyContinue)
{
  Invoke-Expression (&starship init powershell)
}

# FZF options
if (Get-Command fzf -ErrorAction SilentlyContinue)
{
  $env:FZF_DEFAULT_OPTS = "--reverse --border --bind 'alt-j:down,alt-k:up'"
}

# Zoxide initialization
if (Get-Command zoxide -ErrorAction SilentlyContinue)
{
  Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}
