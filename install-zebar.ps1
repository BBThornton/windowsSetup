[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "waybar-mirror"
$targetRoot = Join-Path $HOME ".glzr\zebar"
$target = Join-Path $targetRoot "waybar-mirror"

if (-not (Test-Path $source)) {
  throw "Cannot find source widget pack: $source"
}

New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

if (Test-Path $target) {
  $backup = "$target.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  Move-Item -Path $target -Destination $backup
  Write-Host "Backed up existing pack to $backup"
}

Copy-Item -Path $source -Destination $target -Recurse

Write-Host "Installed Zebar widget pack to $target"
Write-Host "Open Zebar from the tray, then enable: Widget packs -> Waybar Mirror -> Top Bar."
Write-Host "Set Run on startup there if you want Zebar to open it automatically."
