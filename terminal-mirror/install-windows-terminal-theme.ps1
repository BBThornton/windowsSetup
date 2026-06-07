[CmdletBinding()]
param(
  [string]$Distro = "archlinux",
  [string]$ProfileName = "Arch (mirror)",
  [string]$FontFace = "JetBrainsMono Nerd Font Mono",
  [int]$FontSize = 12,
  [int]$Opacity = 90,
  [switch]$SetAsDefault
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common.ps1")

$SettingsPath = Get-WindowsTerminalSettingsPath
Write-Host "Using Windows Terminal settings: $SettingsPath"

if (-not (Test-NerdFontFamilyInstalled -FilePattern "*JetBrainsMonoNerdFontMono-Regular*.ttf")) {
  Write-Warning "JetBrainsMono Nerd Font Mono was not found for the current user."
  Write-Warning "Run ..\install-hyprwin.ps1 first (it installs this font), or pass -FontFace to use a font you already have."
}

$Settings = Get-WindowsTerminalSettings -Path $SettingsPath

Add-ColorScheme -Settings $Settings -Scheme (Get-CatppuccinMochaScheme)

$WslProfile = Set-WslLaunchProfile -Settings $Settings -ProfileName $ProfileName -Distro $Distro `
  -ColorScheme "Catppuccin Mocha" -FontFace $FontFace -FontSize $FontSize -Opacity $Opacity

if ($SetAsDefault) {
  $Settings | Add-Member -NotePropertyName 'defaultProfile' -NotePropertyValue $WslProfile.guid -Force
  Write-Host "Set '$ProfileName' as the default profile."
}

Save-WindowsTerminalSettings -Path $SettingsPath -Settings $Settings

Write-Host ""
Write-Host "Done. Restart Windows Terminal, then open the '$ProfileName' profile to see the theme."
