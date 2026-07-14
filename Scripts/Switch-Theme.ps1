#Requires -Version 5.1
<#
.SYNOPSIS
    Switches application themes to match Windows' current Light/Dark mode setting.

.DESCRIPTION
    Port of a Hyprland/rofi theme-switcher to Windows PowerShell. Instead of an
    interactive rofi menu, the theme is chosen automatically from the Windows
    "Choose your color" setting (Settings > Personalization > Colors), which is
    read from the registry. This script only reads that setting — actually
    switching Windows' own Light/Dark mode is left to PowerToys' Light Switch
    module, so the two don't fight over the same registry keys.

    Theme folders are expected at: $HOME\.config\themes\<light|dark>\
    Each theme folder may contain:
        windows-terminal.json   -> merged into Windows Terminal settings.json
        neovim.lua               -> nvim colorscheme file
        lazygit.yml               -> lazygit config
        btop.theme                -> btop theme file
        variable.ps1              -> dot-sourced; may set $VSCodeTheme, $BatTheme, $EmacsTheme

.PARAMETER Mode
    'Auto' (default) detects the current Windows theme. 'Light' or 'Dark' forces one.

.PARAMETER Watch
    Keeps running and re-applies the theme whenever Windows' Light/Dark setting changes.

.EXAMPLE
    .\Switch-Theme.ps1
    .\Switch-Theme.ps1 -Mode Dark
    .\Switch-Theme.ps1 -Watch
#>

[CmdletBinding()]
param(
  [ValidateSet('Auto', 'Light', 'Dark')]
  [string]$Mode = 'Auto',

  [switch]$Watch
)

# --- Configuration ---
$ThemesDir = Join-Path $HOME '.config\themes'

# Map of theme-folder filename -> destination path on this machine.
# Adjust WindowsTerminal path if you're using the Store vs. portable build.
$Targets = @{
  'windows-terminal.json' = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  'neovim.lua'            = "$HOME\AppData\Local\nvim\lua\plugins\colorscheme.lua"
  'lazygit.yml'           = "$env:LOCALAPPDATA\lazygit\config.yml"
  'btop.theme'            = "$HOME\.config\btop\themes\current.theme"
}

$PersonalizeKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

# --- Pre-flight check ---
if (-not (Test-Path $ThemesDir))
{
  Write-Host "Themes directory not found: $ThemesDir" -ForegroundColor Yellow
  Write-Host "Copy your theme folders there first, e.g.:" -ForegroundColor Yellow
  Write-Host "  $ThemesDir\gruvbox-dark\"  -ForegroundColor Yellow
  Write-Host "  $ThemesDir\gruvbox-light\" -ForegroundColor Yellow
  exit 1
}

# --- Functions ---

function Get-WindowsThemeMode
{
  <# Reads the OS "app mode" (light/dark) from the registry. #>
  try
  {
    $val = Get-ItemPropertyValue -Path $PersonalizeKey -Name AppsUseLightTheme -ErrorAction Stop
    if ($val -eq 1)
    { 'light' 
    } else
    { 'dark' 
    }
  } catch
  {
    'light'
  }
}

function Resolve-ThemeName
{
  param([string]$RequestedMode)
  if ($RequestedMode -eq 'Auto')
  { return "gruvbox-$(Get-WindowsThemeMode)" 
  }
  return "gruvbox-$($RequestedMode.ToLower())"
}

function Show-ThemeNotification
{
  param([string]$Title, [string]$Message)
  if (Get-Module -ListAvailable -Name BurntToast)
  {
    Import-Module BurntToast -ErrorAction SilentlyContinue
    New-BurntToastNotification -Text $Title, $Message
  } else
  {
    Write-Host "$Title - $Message"
  }
}

function Copy-ThemeFiles
{
  param([string]$Theme)
  foreach ($file in $Targets.Keys)
  {
    $source = Join-Path $ThemesDir "$Theme\$file"
    $target = $Targets[$file]
    if (Test-Path $source)
    {
      $targetDir = Split-Path $target -Parent
      if ($targetDir -and -not (Test-Path $targetDir))
      {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
      }
      Copy-Item -Path $source -Destination $target -Force
    }
  }
}

function Update-Starship
{
  param([string]$Theme)
  $configFile = "$HOME\.config\starship.toml"
  if ((Get-Command starship -ErrorAction SilentlyContinue) -and (Test-Path $configFile))
  {
    $palette = $Theme -replace '-', '_'
    (Get-Content $configFile) -replace "palette = '.*'", "palette = '$palette'" |
      Set-Content $configFile
  }
}

function Update-VSCode
{
  param([string]$VSCodeThemeName)
  if ((Get-Command code -ErrorAction SilentlyContinue) -and $VSCodeThemeName)
  {
    $settingsFile = "$env:APPDATA\Code\User\settings.json"
    if (Test-Path $settingsFile)
    {
      $content = Get-Content $settingsFile -Raw
      $content = $content -replace '"workbench\.colorTheme":\s*".*?"', "`"workbench.colorTheme`": `"$VSCodeThemeName`""
      Set-Content -Path $settingsFile -Value $content
    }
  }
}

function Update-Bat
{
  param([string]$BatTheme)
  if ((Get-Command bat -ErrorAction SilentlyContinue) -and $BatTheme)
  {
    $configFile = "$HOME\.config\bat\config"
    if (Test-Path $configFile)
    {
      (Get-Content $configFile) -replace '--theme=.*', "--theme=`"$BatTheme`"" |
        Set-Content $configFile
      bat cache --build | Out-Null
    }
  }
}

function Update-Emacs
{
  param([string]$EmacsTheme)
  if ((Get-Command emacs -ErrorAction SilentlyContinue) -and $EmacsTheme)
  {
    foreach ($f in @("$HOME\.config\doom\config.org", "$HOME\.config\doom\config.el"))
    {
      if (Test-Path $f)
      {
        (Get-Content $f) -replace "\(setq doom-theme '.*\)", "(setq doom-theme '$EmacsTheme)" |
          Set-Content $f
      }
    }
    if (Get-Command emacsclient -ErrorAction SilentlyContinue)
    {
      emacsclient -e "(progn (mapc #'disable-theme custom-enabled-themes) (load-theme '$EmacsTheme t) (doom/reload-theme))" | Out-Null
    }
  }
}

# --- Main ---

function Invoke-ThemeSwitch
{
  param([string]$RequestedMode)

  $theme = Resolve-ThemeName -RequestedMode $RequestedMode
  $variableFile = Join-Path $ThemesDir "$theme\variable.ps1"

  # Reset per-theme variables so a previous run can't leak into this one.
  $VSCodeTheme = $null
  $BatTheme = $null
  $EmacsTheme = $null

  if (Test-Path $variableFile)
  {
    . $variableFile
  } else
  {
    Write-Warning "No variable.ps1 found for theme '$theme' at $variableFile"
  }

  Copy-ThemeFiles -Theme $theme
  Update-Starship -Theme $theme
  Update-VSCode -VSCodeThemeName $VSCodeTheme
  Update-Bat -BatTheme $BatTheme
  Update-Emacs -EmacsTheme $EmacsTheme

  Show-ThemeNotification -Title 'Theme Applied' -Message "Switched to $theme"
}

if ($Watch)
{
  Write-Host "Watching Windows theme changes (Ctrl+C to stop)..."
  $lastTheme = $null
  while ($true)
  {
    $current = Get-WindowsThemeMode
    if ($current -ne $lastTheme)
    {
      Invoke-ThemeSwitch -RequestedMode 'Auto'
      $lastTheme = $current
    }
    Start-Sleep -Seconds 5
  }
} else
{
  Invoke-ThemeSwitch -RequestedMode $Mode
}
