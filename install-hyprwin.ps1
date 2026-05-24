[CmdletBinding()]
param(
  [switch]$NoBackup,
  [switch]$NoAutoHotkeyStartup,
  [switch]$NoFontInstall,
  [switch]$CleanZebarBackups,
  [switch]$Start,
  [switch]$Restart
)

$ErrorActionPreference = "Stop"

$RepoRoot = $PSScriptRoot
$InstallRoot = Join-Path $env:USERPROFILE ".glzr"
$GlazeRoot = Join-Path $InstallRoot "glazewm"
$ZebarRoot = Join-Path $InstallRoot "zebar"
$HyprwinRoot = Join-Path $InstallRoot "hyprwin"
$StartupRoot = [Environment]::GetFolderPath("Startup")

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$JetBrainsMonoNerdFontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

function Remove-ZebarBackups {
  $BackupPattern = Join-Path $ZebarRoot "waybar-mirror.backup-*"
  Get-ChildItem -Path $BackupPattern -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
    Write-Host "Removed Zebar backup: $($_.FullName)"
  }
}

function Assert-SourceFile {
  param([Parameter(Mandatory)] [string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Missing required file: $Path"
  }
}

function Assert-SourceDirectory {
  param([Parameter(Mandatory)] [string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    throw "Missing required directory: $Path"
  }
}

function Backup-Path {
  param([Parameter(Mandatory)] [string]$Path)

  if ($NoBackup -or -not (Test-Path -LiteralPath $Path)) {
    return
  }

  if ($CleanZebarBackups -and $Path -eq $ZebarPackTarget) {
    Remove-Item -LiteralPath $Path -Recurse -Force
    Write-Host "Removed existing Zebar pack: $Path"
    return
  }

  $BackupPath = "$Path.backup-$Timestamp"
  Move-Item -LiteralPath $Path -Destination $BackupPath
  Write-Host "Backed up $Path -> $BackupPath"
}

function Install-File {
  param(
    [Parameter(Mandatory)] [string]$Source,
    [Parameter(Mandatory)] [string]$Destination
  )

  Assert-SourceFile -Path $Source

  $Parent = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $Parent | Out-Null
  Backup-Path -Path $Destination
  Copy-Item -LiteralPath $Source -Destination $Destination -Force
  Write-Host "Installed file: $Destination"
}

function Install-Directory {
  param(
    [Parameter(Mandatory)] [string]$Source,
    [Parameter(Mandatory)] [string]$Destination
  )

  Assert-SourceDirectory -Path $Source

  $Parent = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $Parent | Out-Null
  Backup-Path -Path $Destination
  Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
  Write-Host "Installed directory: $Destination"
}

function Install-JetBrainsMonoNerdFont {
  $FontInstallRoot = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
  $TempRoot = Join-Path ([IO.Path]::GetTempPath()) "hyprwin-fonts-$Timestamp"
  $ZipPath = Join-Path $TempRoot "JetBrainsMono.zip"
  $ExtractRoot = Join-Path $TempRoot "JetBrainsMono"
  $RegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

  New-Item -ItemType Directory -Force -Path $FontInstallRoot, $TempRoot, $ExtractRoot | Out-Null
  New-Item -Path $RegistryPath -Force | Out-Null

  Write-Host "Downloading JetBrainsMono Nerd Font..."
  Invoke-WebRequest -Uri $JetBrainsMonoNerdFontUrl -OutFile $ZipPath

  Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractRoot -Force

  $FontFiles = Get-ChildItem -LiteralPath $ExtractRoot -Recurse -File |
    Where-Object { $_.Extension -in @(".ttf", ".otf") -and $_.Name -notmatch "Windows Compatible" }

  if (-not $FontFiles) {
    throw "Downloaded JetBrainsMono Nerd Font archive did not contain installable font files."
  }

  foreach ($FontFile in $FontFiles) {
    $Destination = Join-Path $FontInstallRoot $FontFile.Name
    Copy-Item -LiteralPath $FontFile.FullName -Destination $Destination -Force

    $FontType = if ($FontFile.Extension -eq ".otf") { "OpenType" } else { "TrueType" }
    $RegistryName = "JetBrainsMono Nerd Font $($FontFile.BaseName) ($FontType)"

    New-ItemProperty -Path $RegistryPath -Name $RegistryName -Value $Destination -PropertyType String -Force | Out-Null
  }

  Remove-Item -LiteralPath $TempRoot -Recurse -Force
  Write-Host "Installed JetBrainsMono Nerd Font for the current user."
  Write-Host "Restart Zebar and any terminals/apps that need the font."
}

function Resolve-AutoHotkey {
  $Candidates = @(
    (Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue).Source,
    (Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue).Source
  )

  foreach ($ProgramRoot in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if ($ProgramRoot) {
      $Candidates += Join-Path $ProgramRoot "AutoHotkey\v2\AutoHotkey64.exe"
      $Candidates += Join-Path $ProgramRoot "AutoHotkey\v2\AutoHotkey.exe"
    }
  }

  $Candidates = $Candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }

  return $Candidates | Select-Object -First 1
}

function New-StartupShortcut {
  param(
    [Parameter(Mandatory)] [string]$ShortcutPath,
    [Parameter(Mandatory)] [string]$TargetPath
  )

  $AutoHotkey = Resolve-AutoHotkey

  if (-not $AutoHotkey) {
    Write-Warning "AutoHotkey v2 was not found. Installed alt-drag.ahk, but did not create a startup shortcut."
    Write-Warning "Install AutoHotkey v2, then rerun this script or launch $TargetPath manually."
    return
  }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ShortcutPath) | Out-Null

  $Shell = New-Object -ComObject WScript.Shell
  $Shortcut = $Shell.CreateShortcut($ShortcutPath)
  $Shortcut.TargetPath = $AutoHotkey
  $Shortcut.Arguments = "`"$TargetPath`""
  $Shortcut.WorkingDirectory = Split-Path -Parent $TargetPath
  $Shortcut.Description = "Hyprwin Alt-drag helper"
  $Shortcut.Save()

  Write-Host "Installed startup shortcut: $ShortcutPath"
}

function Invoke-OptionalStart {
  if (-not ($Start -or $Restart)) {
    return
  }

  if ($Restart) {
    Get-Process -Name "zebar" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "glazewm" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "AutoHotkey64", "AutoHotkey" -ErrorAction SilentlyContinue | Stop-Process -Force
  }

  $Glaze = Get-Command "glazewm.exe" -ErrorAction SilentlyContinue
  $Zebar = Get-Command "zebar.exe" -ErrorAction SilentlyContinue
  $AutoHotkey = Resolve-AutoHotkey

  if ($Glaze) {
    Start-Process -FilePath $Glaze.Source
    Write-Host "Started GlazeWM."
  } else {
    Write-Warning "glazewm.exe was not found on PATH. Start GlazeWM manually or add it to PATH."
  }

  if ($Zebar) {
    Start-Process -FilePath $Zebar.Source
    Write-Host "Started Zebar."
  } else {
    Write-Warning "zebar.exe was not found on PATH. GlazeWM startup_commands may still start it if configured."
  }

  if ($AutoHotkey) {
    Start-Process -FilePath $AutoHotkey -ArgumentList "`"$(Join-Path $HyprwinRoot "alt-drag.ahk")`""
    Write-Host "Started AutoHotkey alt-drag helper."
  }
}

$GlazeConfigSource = Join-Path $RepoRoot "glazewm.yaml"
$GlazeConfigTarget = Join-Path $GlazeRoot "config.yaml"
$ZebarPackSource = Join-Path $RepoRoot "waybar-mirror"
$ZebarPackTarget = Join-Path $ZebarRoot "waybar-mirror"
$AutoHotkeySource = Join-Path $RepoRoot "alt-drag.ahk"
$AutoHotkeyTarget = Join-Path $HyprwinRoot "alt-drag.ahk"
$AutoHotkeyStartSource = Join-Path $RepoRoot "start-alt-drag.ps1"
$AutoHotkeyStartTarget = Join-Path $HyprwinRoot "start-alt-drag.ps1"
$AutoHotkeyShortcut = Join-Path $StartupRoot "hyprwin-alt-drag.lnk"

if ($CleanZebarBackups) {
  Remove-ZebarBackups
}

if (-not $NoFontInstall) {
  Install-JetBrainsMonoNerdFont
} else {
  Write-Host "Skipped JetBrainsMono Nerd Font install."
}

Install-File -Source $GlazeConfigSource -Destination $GlazeConfigTarget
Install-Directory -Source $ZebarPackSource -Destination $ZebarPackTarget
Install-File -Source $AutoHotkeySource -Destination $AutoHotkeyTarget
Install-File -Source $AutoHotkeyStartSource -Destination $AutoHotkeyStartTarget

if (-not $NoAutoHotkeyStartup) {
  New-StartupShortcut -ShortcutPath $AutoHotkeyShortcut -TargetPath $AutoHotkeyTarget
} else {
  Write-Host "Skipped AutoHotkey startup shortcut."
}

Invoke-OptionalStart

Write-Host ""
Write-Host "Hyprwin install complete."
Write-Host "GlazeWM config: $GlazeConfigTarget"
Write-Host "Zebar pack:     $ZebarPackTarget"
Write-Host "Alt-drag AHK:   $AutoHotkeyTarget"
Write-Host ""
Write-Host "In Zebar, enable: Widget packs -> Waybar Mirror -> Top Bar."
Write-Host "In Zebar, also enable Run on startup for that widget if desired."
