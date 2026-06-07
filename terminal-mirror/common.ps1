# Shared helpers for the terminal-mirror Windows-side installers.
# Dot-source this file; it defines functions only and does not run anything.

function Backup-FileCopy {
  param([Parameter(Mandatory)] [string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return
  }

  $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $BackupPath = "$Path.backup-$Timestamp"
  Copy-Item -LiteralPath $Path -Destination $BackupPath -Force
  Write-Host "Backed up $Path -> $BackupPath"
}

function Get-WindowsTerminalSettingsPath {
  $Candidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
  )

  foreach ($Candidate in $Candidates) {
    if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
      return $Candidate
    }
  }

  throw "Could not find Windows Terminal settings.json. Is Windows Terminal installed?"
}

function ConvertFrom-Jsonc {
  param([Parameter(Mandatory)] [string]$Raw)

  # settings.json is technically JSONC. ConvertFrom-Json can't handle comments,
  # so strip whole-line "//" comments (the style Windows Terminal generates)
  # before parsing. Trailing same-line comments are intentionally left alone
  # since stripping them risks corrupting strings such as icon URLs.
  $Stripped = ($Raw -split "`r?`n" | Where-Object { $_.TrimStart() -notmatch '^//' }) -join "`n"
  return $Stripped | ConvertFrom-Json -Depth 32
}

function Get-WindowsTerminalSettings {
  param([Parameter(Mandatory)] [string]$Path)

  $Raw = Get-Content -LiteralPath $Path -Raw
  return ConvertFrom-Jsonc -Raw $Raw
}

function Save-WindowsTerminalSettings {
  param(
    [Parameter(Mandatory)] [string]$Path,
    [Parameter(Mandatory)] $Settings
  )

  Backup-FileCopy -Path $Path
  ($Settings | ConvertTo-Json -Depth 32) | Set-Content -LiteralPath $Path -Encoding utf8
  Write-Host "Updated Windows Terminal settings: $Path"
}

function Add-ColorScheme {
  param(
    [Parameter(Mandatory)] $Settings,
    [Parameter(Mandatory)] [hashtable]$Scheme
  )

  if (-not $Settings.PSObject.Properties['schemes']) {
    $Settings | Add-Member -NotePropertyName 'schemes' -NotePropertyValue @() -Force
  }

  $Existing = $Settings.schemes | Where-Object { $_.name -eq $Scheme.name } | Select-Object -First 1
  if ($Existing) {
    Write-Host "Color scheme '$($Scheme.name)' already present. Skipping."
    return
  }

  $Settings.schemes = @($Settings.schemes) + [PSCustomObject]$Scheme
  Write-Host "Added color scheme '$($Scheme.name)'."
}

function Set-WslLaunchProfile {
  param(
    [Parameter(Mandatory)] $Settings,
    [Parameter(Mandatory)] [string]$ProfileName,
    [Parameter(Mandatory)] [string]$Distro,
    [Parameter(Mandatory)] [string]$ColorScheme,
    [Parameter(Mandatory)] [string]$FontFace,
    [int]$FontSize = 12,
    [int]$Opacity = 90
  )

  if (-not $Settings.profiles.PSObject.Properties['list']) {
    $Settings.profiles | Add-Member -NotePropertyName 'list' -NotePropertyValue @() -Force
  }

  $ProfileEntry = $Settings.profiles.list | Where-Object { $_.name -eq $ProfileName } | Select-Object -First 1

  if (-not $ProfileEntry) {
    $ProfileEntry = [PSCustomObject]@{
      guid              = "{$([guid]::NewGuid().ToString())}"
      name              = $ProfileName
      commandline       = "wsl.exe -d $Distro"
      startingDirectory = "~"
    }
    $Settings.profiles.list = @($Settings.profiles.list) + $ProfileEntry
    Write-Host "Created Windows Terminal profile '$ProfileName'."
  } else {
    Write-Host "Updating existing Windows Terminal profile '$ProfileName'."
  }

  $ProfileEntry | Add-Member -NotePropertyName 'colorScheme' -NotePropertyValue $ColorScheme -Force
  $ProfileEntry | Add-Member -NotePropertyName 'opacity' -NotePropertyValue $Opacity -Force
  $ProfileEntry | Add-Member -NotePropertyName 'font' -NotePropertyValue ([PSCustomObject]@{ face = $FontFace; size = $FontSize }) -Force

  return $ProfileEntry
}

function Set-ProfileAppearanceByGuid {
  param(
    [Parameter(Mandatory)] $Settings,
    [Parameter(Mandatory)] [string]$Guid,
    [Parameter(Mandatory)] [string]$ColorScheme,
    [Parameter(Mandatory)] [string]$FontFace,
    [int]$FontSize = 12,
    [int]$Opacity = 90
  )

  if (-not $Settings.profiles.PSObject.Properties['list']) {
    return $null
  }

  $ProfileEntry = $Settings.profiles.list | Where-Object { $_.guid -eq $Guid } | Select-Object -First 1
  if (-not $ProfileEntry) {
    return $null
  }

  $ProfileEntry | Add-Member -NotePropertyName 'colorScheme' -NotePropertyValue $ColorScheme -Force
  $ProfileEntry | Add-Member -NotePropertyName 'opacity' -NotePropertyValue $Opacity -Force
  $ProfileEntry | Add-Member -NotePropertyName 'font' -NotePropertyValue ([PSCustomObject]@{ face = $FontFace; size = $FontSize }) -Force

  return $ProfileEntry
}

function Test-NerdFontFamilyInstalled {
  param([Parameter(Mandatory)] [string]$FilePattern)

  $FontFolders = @(
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"),
    (Join-Path $env:WINDIR "Fonts")
  )

  foreach ($FontFolder in $FontFolders) {
    if ((Test-Path -LiteralPath $FontFolder) -and
        (Get-ChildItem -LiteralPath $FontFolder -File -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -like $FilePattern } | Select-Object -First 1)) {
      return $true
    }
  }

  return $false
}

# Catppuccin Mocha — https://github.com/catppuccin/windows-terminal
$script:CatppuccinMochaScheme = @{
  name                = "Catppuccin Mocha"
  background          = "#1E1E2E"
  foreground          = "#CDD6F4"
  cursorColor         = "#F5E0DC"
  selectionBackground = "#585B70"
  black               = "#45475A"
  red                 = "#F38BA8"
  green               = "#A6E3A1"
  yellow              = "#F9E2AF"
  blue                = "#89B4FA"
  purple              = "#F5C2E7"
  cyan                = "#94E2D5"
  white               = "#BAC2DE"
  brightBlack         = "#585B70"
  brightRed           = "#F38BA8"
  brightGreen         = "#A6E3A1"
  brightYellow        = "#F9E2AF"
  brightBlue          = "#89B4FA"
  brightPurple        = "#F5C2E7"
  brightCyan          = "#94E2D5"
  brightWhite         = "#A6ADC8"
}

function Get-CatppuccinMochaScheme {
  return $script:CatppuccinMochaScheme.Clone()
}
