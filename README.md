# Hyprwin

Windows GlazeWM + Zebar setup that mirrors this machine's Hyprland/Waybar workflow as closely as practical.

## Included

- `glazewm.yaml` - GlazeWM config with Hyprland-like gaps, workspaces, focus behavior, borders, and keybindings.
- `waybar-mirror/` - Zebar v3 widget pack modeled after the local Waybar `TOP-Default` layout.
- `alt-drag.ahk` - AutoHotkey v2 helper for Alt + mouse move/resize.
- `start-alt-drag.ps1` - Direct launcher for testing the AutoHotkey helper.
- `install-hyprwin.ps1` - Full installer for all of the above.
- `terminal-mirror/` - Arch-on-WSL2 + Windows Terminal + PowerShell setup that mirrors this machine's zsh/terminal workflow. See `terminal-mirror/README.md`.

## Install

Run from PowerShell on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-hyprwin.ps1
```

The installer backs up existing targets, then copies:

- `glazewm.yaml` to `%USERPROFILE%\.glzr\glazewm\config.yaml`
- `waybar-mirror\` to `%USERPROFILE%\.glzr\zebar\waybar-mirror\`
- `alt-drag.ahk` to `%USERPROFILE%\.glzr\hyprwin\alt-drag.ahk`

It also installs JetBrainsMono Nerd Font for the current Windows user unless `-NoFontInstall` is passed. Use `-ForceFontInstall` to repair a bad or stale font install.

## After Install

Open Zebar from the tray and enable:

```text
Widget packs -> Waybar Mirror -> Top Bar
```

Enable `Run on startup` for that widget if you want Zebar to restore it automatically.

## Requirements

- GlazeWM
- Zebar v3
- AutoHotkey v2 for `alt-drag.ahk`
- Internet access for the default JetBrainsMono Nerd Font install

See `INSTALL-HYPRWIN.md` for installer options.
