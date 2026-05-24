# Hyprwin Install

Run this from PowerShell on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-hyprwin.ps1
```

The installer copies:

```text
glazewm.yaml        -> %USERPROFILE%\.glzr\glazewm\config.yaml
waybar-mirror\      -> %USERPROFILE%\.glzr\zebar\waybar-mirror\
alt-drag.ahk        -> %USERPROFILE%\.glzr\hyprwin\alt-drag.ahk
start-alt-drag.ps1  -> %USERPROFILE%\.glzr\hyprwin\start-alt-drag.ps1
```

The Zebar pack follows the official v3 format with `htmlPath` set to `./index.html`.

By default it also creates a Startup folder shortcut for the AutoHotkey alt-drag helper:

```text
shell:startup\hyprwin-alt-drag.lnk
```

Useful options:

```powershell
.\install-hyprwin.ps1 -Restart
.\install-hyprwin.ps1 -Start
.\install-hyprwin.ps1 -NoBackup
.\install-hyprwin.ps1 -NoAutoHotkeyStartup
.\install-hyprwin.ps1 -NoFontInstall
.\install-hyprwin.ps1 -CleanZebarBackups
```

To test the AutoHotkey helper immediately:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.glzr\hyprwin\start-alt-drag.ps1"
```

After install, open Zebar from the tray and enable:

```text
Widget packs -> Waybar Mirror -> Top Bar
```

Also enable `Run on startup` for that widget from Zebar's tray menu if you want Zebar to restore it automatically.

Requirements:

- GlazeWM installed.
- Zebar installed.
- AutoHotkey v2 installed if you want `alt-drag.ahk`.
- Internet access for the default JetBrainsMono Nerd Font install.

The installer downloads JetBrainsMono Nerd Font from the Nerd Fonts GitHub release URL and installs it for the current Windows user. Use `-NoFontInstall` to skip that step.
