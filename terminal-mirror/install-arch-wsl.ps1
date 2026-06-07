[CmdletBinding()]
param(
  [string]$Distro = "archlinux"
)

$ErrorActionPreference = "Stop"

function Get-InstalledWslDistros {
  $Raw = (wsl.exe --list --quiet) 2>$null
  if (-not $Raw) {
    return @()
  }

  return $Raw -replace "`0", "" -split "`r?`n" |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }
}

function Test-WslDistroAvailableOnline {
  param([Parameter(Mandatory)] [string]$Name)

  $Raw = (wsl.exe --list --online) 2>$null
  if (-not $Raw) {
    return $false
  }

  $Lines = $Raw -replace "`0", "" -split "`r?`n"
  return [bool]($Lines | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\b" })
}

$Installed = Get-InstalledWslDistros

if ($Installed -contains $Distro) {
  Write-Host "WSL distro '$Distro' is already installed. Nothing to do."
  Write-Host "Launch it with: wsl -d $Distro"
} else {
  if (-not (Test-WslDistroAvailableOnline -Name $Distro)) {
    throw @"
'$Distro' is not listed by 'wsl --list --online' on this machine.
Microsoft ships an official Arch Linux WSL distro, but availability depends on
your Windows/WSL version. As a fallback, install the community ArchWSL image:
https://github.com/yuk7/ArchWSL
"@
  }

  Write-Host "Installing WSL distro '$Distro' (this can take a few minutes)..."
  wsl.exe --install -d $Distro

  Write-Host ""
  Write-Host "Arch is installed. WSL needs a fresh terminal session before it can launch a"
  Write-Host "newly installed distro -- close this window, reopen Windows Terminal, then run:"
  Write-Host ""
  Write-Host "    wsl -d $Distro"
  Write-Host ""
  Write-Host "On first launch, Arch will ask you to create a Linux user account and password."
  Write-Host "Once that's done, continue with setup-arch-shell.sh -- see README.md for the command."
}
