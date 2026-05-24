# Zebar Install

This repo now uses the Zebar v3 widget-pack layout:

```text
waybar-mirror/
  zpack.json
  index.html
  styles.css
```

Install it on Windows with PowerShell from this repo:

```powershell
.\install-zebar.ps1
```

For the full GlazeWM + Zebar + AutoHotkey setup, run:

```powershell
.\install-hyprwin.ps1
```

That copies the pack to:

```text
%USERPROFILE%\.glzr\zebar\waybar-mirror
```

The installer also rewrites `zpack.json` so `htmlPath` points at the absolute installed `index.html` path required by Zebar.

Then open Zebar from the tray and enable:

```text
Widget packs -> Waybar Mirror -> Top Bar
```

To start it automatically, right-click Zebar in the tray and enable:

```text
Widget packs -> Waybar Mirror -> Top Bar -> Run on startup
```

`glazewm.yaml` already starts Zebar with:

```yaml
startup_commands:
  - "shell-exec zebar"
```

If Zebar is not on `PATH`, replace that command with the full path to `zebar.exe`.
