[CmdletBinding()]
param(
  [string]$FontFace = "JetBrainsMono Nerd Font Mono",
  [int]$FontSize = 12,
  [int]$Opacity = 90,
  [switch]$NoModules,
  [switch]$NoProfile
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common.ps1")

# Static, documented GUID for the built-in "Windows PowerShell" profile.
# PowerShell 7's profile GUID is generated per-machine and can't be predicted,
# so that one is left to a one-time manual theme pick (see closing message).
$WindowsPowerShellGuid = "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}"

$ProfileBlockMarkerStart = "# >>> terminal-mirror profile block >>>"
$ProfileBlockMarkerEnd   = "# <<< terminal-mirror profile block <<<"

function Install-OhMyPosh {
  if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "oh-my-posh already installed, skipping."
    return
  }

  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required to install oh-my-posh. Install 'App Installer' from the Microsoft Store, then re-run."
  }

  Write-Host "Installing oh-my-posh via winget..."
  winget install -e --id JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements
}

function Install-ProfileModules {
  foreach ($Module in @("Terminal-Icons", "PSFzf", "posh-git")) {
    if (Get-Module -ListAvailable -Name $Module) {
      Write-Host "$Module already installed, skipping."
    } else {
      Write-Host "Installing module $Module..."
      Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
    }
  }
}

function Get-OhMyPoshThemeConfig {
  # POSH_THEMES_PATH is set by the installer but may not be refreshed in this
  # session; fall back to the standard winget install location.
  $Candidates = @($env:POSH_THEMES_PATH, (Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"))

  foreach ($ThemesPath in $Candidates) {
    if (-not $ThemesPath -or -not (Test-Path -LiteralPath $ThemesPath)) {
      continue
    }

    $Match = Get-ChildItem -LiteralPath $ThemesPath -Filter "*.omp.json" -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "*catppuccin*mocha*" } |
      Select-Object -First 1

    if ($Match) {
      return $Match.FullName
    }
  }

  return $null
}

function Get-ProfileBlock {
  param([Parameter(Mandatory)] [string]$InitLine)

  return @"
$ProfileBlockMarkerStart
$InitLine

Import-Module Terminal-Icons
Import-Module posh-git
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
$ProfileBlockMarkerEnd
"@
}

function Install-ThemedProfile {
  param([Parameter(Mandatory)] [string]$InitLine)

  $ProfileDir = Split-Path -Parent $PROFILE
  New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null

  $Block = Get-ProfileBlock -InitLine $InitLine
  $Existing = ""
  if (Test-Path -LiteralPath $PROFILE -PathType Leaf) {
    $Existing = Get-Content -LiteralPath $PROFILE -Raw
  }

  Backup-FileCopy -Path $PROFILE

  $StartIndex = $Existing.IndexOf($ProfileBlockMarkerStart)
  $EndIndex = $Existing.IndexOf($ProfileBlockMarkerEnd)

  if ($StartIndex -ge 0 -and $EndIndex -ge 0) {
    $EndIndex += $ProfileBlockMarkerEnd.Length
    $Updated = $Existing.Substring(0, $StartIndex) + $Block + $Existing.Substring($EndIndex)
    Set-Content -LiteralPath $PROFILE -Value $Updated -Encoding utf8
    Write-Host "Updated existing terminal-mirror block in $PROFILE"
  } else {
    Add-Content -LiteralPath $PROFILE -Value "`n$Block`n"
    Write-Host "Appended terminal-mirror block to $PROFILE"
  }
}

if ($NoModules) {
  Write-Host "Skipped oh-my-posh / module install (-NoModules)."
} else {
  Install-OhMyPosh
  Install-ProfileModules
}

if ($NoProfile) {
  Write-Host "Skipped `$PROFILE update (-NoProfile)."
} else {
  $ThemeConfig = Get-OhMyPoshThemeConfig
  if ($ThemeConfig) {
    $InitLine = "oh-my-posh init pwsh --config `"$ThemeConfig`" | Invoke-Expression"
  } else {
    Write-Warning "No Catppuccin Mocha oh-my-posh theme found; using oh-my-posh's default theme instead."
    Write-Warning "Browse https://ohmyposh.dev/docs/themes and update the init line in `$PROFILE if you'd like a closer match."
    $InitLine = "oh-my-posh init pwsh | Invoke-Expression"
  }

  Install-ThemedProfile -InitLine $InitLine
}

Write-Host "==> Theming Windows Terminal's 'Windows PowerShell' profile"
$SettingsPath = Get-WindowsTerminalSettingsPath
$Settings = Get-WindowsTerminalSettings -Path $SettingsPath

Add-ColorScheme -Settings $Settings -Scheme (Get-CatppuccinMochaScheme)

$Updated = Set-ProfileAppearanceByGuid -Settings $Settings -Guid $WindowsPowerShellGuid `
  -ColorScheme "Catppuccin Mocha" -FontFace $FontFace -FontSize $FontSize -Opacity $Opacity

if ($Updated) {
  Write-Host "Themed the 'Windows PowerShell' profile."
} else {
  Write-Host "No existing 'Windows PowerShell' profile entry to update -- the scheme is still available to pick manually."
}

Save-WindowsTerminalSettings -Path $SettingsPath -Settings $Settings

Write-Host ""
Write-Host "Done. Restart your PowerShell session to load the new profile and theme."
Write-Host ""
Write-Host "PowerShell 7's profile GUID is generated per-machine and can't be set from here."
Write-Host "To match it up: Settings -> PowerShell -> Appearance -> Color scheme: Catppuccin Mocha,"
Write-Host "Font face: $FontFace."
