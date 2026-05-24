[CmdletBinding()]
param(
  [switch]$NoBackup,
  [switch]$NoAltSnapStartup,
  [switch]$NoFontInstall,
  [switch]$ForceFontInstall,
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
$AltSnapUrl = "https://api.github.com/repos/RamonUnch/AltSnap/releases/latest"

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

function Test-JetBrainsMonoNerdFontInstalled {
  $RegistryPaths = @(
    "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts",
    "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
  )
  $RequiredFontPatterns = @(
    "*JetBrainsMonoNerdFont-Regular*.ttf",
    "*JetBrainsMonoNerdFont-Bold*.ttf"
  )

  $FontFolders = @(
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"),
    (Join-Path $env:WINDIR "Fonts")
  )

  $FoundRequiredFiles = 0

  foreach ($Pattern in $RequiredFontPatterns) {
    $FoundFileForPattern = $false

    foreach ($FontFolder in $FontFolders) {
      if ((Test-Path -LiteralPath $FontFolder) -and (Get-ChildItem -LiteralPath $FontFolder -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $Pattern } | Select-Object -First 1)) {
        $FoundFileForPattern = $true
        break
      }
    }

    if ($FoundFileForPattern) {
      $FoundRequiredFiles += 1
    }
  }

  if ($FoundRequiredFiles -lt $RequiredFontPatterns.Count) {
    return $false
  }

  foreach ($RegistryPath in $RegistryPaths) {
    if (Test-Path -LiteralPath $RegistryPath) {
      $FontRegistry = Get-ItemProperty -LiteralPath $RegistryPath
      $RegisteredFont = $FontRegistry.PSObject.Properties |
        Where-Object {
          ($_.Name -eq "JetBrainsMono Nerd Font (TrueType)" -or $_.Name -like "JetBrainsMono Nerd Font*Regular*") -and
          $_.Value -like "*JetBrainsMonoNerdFont-Regular*.ttf"
        } |
        Select-Object -First 1

      if ($RegisteredFont) {
        return $true
      }
    }
  }

  return $false
}

function Install-FontFile {
  param(
    [Parameter(Mandatory)] [System.IO.FileInfo]$FontFile,
    [Parameter(Mandatory)] [string]$FontInstallRoot,
    [Parameter(Mandatory)] [string]$RegistryPath
  )

  $Destination = Join-Path $FontInstallRoot $FontFile.Name
  Copy-Item -LiteralPath $FontFile.FullName -Destination $Destination -Force

  $FontType = if ($FontFile.Extension -eq ".otf") { "OpenType" } else { "TrueType" }
  $RegistryName = "JetBrainsMono Nerd Font $($FontFile.BaseName) ($FontType)"

  New-ItemProperty -Path $RegistryPath -Name $RegistryName -Value $Destination -PropertyType String -Force | Out-Null

  return $Destination
}

function Install-JetBrainsMonoNerdFont {
  if (-not $ForceFontInstall -and (Test-JetBrainsMonoNerdFontInstalled)) {
    Write-Host "JetBrainsMono Nerd Font is already installed. Skipping font download."
    return
  }

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
    Where-Object {
      $_.Extension -in @(".ttf", ".otf") -and
      $_.BaseName -like "JetBrainsMonoNerdFont*" -and
      $_.FullName -match "Windows Compatible"
    }

  if (-not $FontFiles) {
    $FontFiles = Get-ChildItem -LiteralPath $ExtractRoot -Recurse -File |
      Where-Object { $_.Extension -in @(".ttf", ".otf") -and $_.BaseName -like "JetBrainsMonoNerdFont*" }
  }

  if (-not $FontFiles) {
    throw "Downloaded JetBrainsMono Nerd Font archive did not contain JetBrainsMono Nerd Font files."
  }

  $RegularFont = $FontFiles |
    Where-Object { $_.BaseName -match "^JetBrainsMonoNerdFont-Regular" } |
    Select-Object -First 1

  foreach ($FontFile in $FontFiles) {
    Install-FontFile -FontFile $FontFile -FontInstallRoot $FontInstallRoot -RegistryPath $RegistryPath | Out-Null
  }

  if ($RegularFont) {
    $RegularDestination = Join-Path $FontInstallRoot $RegularFont.Name
    New-ItemProperty -Path $RegistryPath -Name "JetBrainsMono Nerd Font (TrueType)" -Value $RegularDestination -PropertyType String -Force | Out-Null
  }

  Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
    [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError=true, CharSet=System.Runtime.InteropServices.CharSet.Auto)]
    public static extern System.IntPtr SendMessageTimeout(
      System.IntPtr hWnd,
      uint Msg,
      System.IntPtr wParam,
      string lParam,
      uint fuFlags,
      uint uTimeout,
      out System.IntPtr lpdwResult);
"@

  $Result = [IntPtr]::Zero
  [Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [IntPtr]::Zero, "Fonts", 0x0002, 1000, [ref]$Result) | Out-Null

  Remove-Item -LiteralPath $TempRoot -Recurse -Force
  Write-Host "Installed JetBrainsMono Nerd Font for the current user."
  Write-Host "Restart Zebar and any terminals/apps that need the font."
}

function Install-AltSnap {
  param([Parameter(Mandatory)] [string]$Destination)

  $Parent = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $Parent | Out-Null

  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  Write-Host "Resolving latest AltSnap release..."
  $Release = Invoke-RestMethod -Uri $AltSnapUrl -UseBasicParsing
  $Asset = $Release.assets |
    Where-Object { $_.name -like "AltSnap*.exe" -and $_.name -notlike "*Setup*" } |
    Select-Object -First 1

  if (-not $Asset) {
    $Names = ($Release.assets | ForEach-Object { $_.name }) -join ", "
    throw "Could not find AltSnap exe in the latest GitHub release. Available assets: $Names"
  }

  Write-Host "Downloading AltSnap $($Release.tag_name)..."
  Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Destination -UseBasicParsing
  Write-Host "Installed AltSnap: $Destination"
}

function New-StartupShortcut {
  param(
    [Parameter(Mandatory)] [string]$ShortcutPath,
    [Parameter(Mandatory)] [string]$TargetPath
  )

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ShortcutPath) | Out-Null

  $Shell = New-Object -ComObject WScript.Shell
  $Shortcut = $Shell.CreateShortcut($ShortcutPath)
  $Shortcut.TargetPath = $TargetPath
  $Shortcut.WorkingDirectory = Split-Path -Parent $TargetPath
  $Shortcut.Description = "Hyprwin AltSnap helper"
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
    Get-Process -Name "AltSnap" -ErrorAction SilentlyContinue | Stop-Process -Force
  }

  $Glaze = Get-Command "glazewm.exe" -ErrorAction SilentlyContinue
  $Zebar = Get-Command "zebar.exe" -ErrorAction SilentlyContinue

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

  if (Test-Path -LiteralPath $AltSnapTarget -PathType Leaf) {
    Start-Process -FilePath $AltSnapTarget -WorkingDirectory $HyprwinRoot
    Write-Host "Started AltSnap."
  }
}

$GlazeConfigSource = Join-Path $RepoRoot "glazewm.yaml"
$GlazeConfigTarget = Join-Path $GlazeRoot "config.yaml"
$ZebarPackSource = Join-Path $RepoRoot "waybar-mirror"
$ZebarPackTarget = Join-Path $ZebarRoot "waybar-mirror"
$AltSnapTarget = Join-Path $HyprwinRoot "AltSnap.exe"
$AltSnapIniSource = Join-Path $RepoRoot "AltSnap.ini"
$AltSnapIniTarget = Join-Path $HyprwinRoot "AltSnap.ini"
$AltSnapShortcut = Join-Path $StartupRoot "hyprwin-altsnap.lnk"

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
Install-AltSnap -Destination $AltSnapTarget
Install-File -Source $AltSnapIniSource -Destination $AltSnapIniTarget

if (-not $NoAltSnapStartup) {
  New-StartupShortcut -ShortcutPath $AltSnapShortcut -TargetPath $AltSnapTarget
} else {
  Write-Host "Skipped AltSnap startup shortcut."
}

Invoke-OptionalStart

Write-Host ""
Write-Host "Hyprwin install complete."
Write-Host "GlazeWM config: $GlazeConfigTarget"
Write-Host "Zebar pack:     $ZebarPackTarget"
Write-Host "AltSnap:        $AltSnapTarget"
Write-Host ""
Write-Host "In Zebar, enable: Widget packs -> Waybar Mirror -> Top Bar."
Write-Host "In Zebar, also enable Run on startup for that widget if desired."
