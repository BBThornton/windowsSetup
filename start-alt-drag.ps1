[CmdletBinding()]
param(
  [string]$ScriptPath = (Join-Path $env:USERPROFILE ".glzr\hyprwin\alt-drag.ahk")
)

$ErrorActionPreference = "Stop"

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

if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
  throw "Cannot find alt-drag script: $ScriptPath. Run install-hyprwin.ps1 first."
}

$AutoHotkey = Resolve-AutoHotkey

if (-not $AutoHotkey) {
  throw "AutoHotkey v2 was not found. Install AutoHotkey v2 from https://www.autohotkey.com/"
}

Start-Process -FilePath $AutoHotkey -ArgumentList "`"$ScriptPath`""
Write-Host "Started $ScriptPath with $AutoHotkey"
