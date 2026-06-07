# Terminal Mirror

Mirrors this machine's Arch/zsh terminal setup onto Windows: Arch Linux on
WSL2 with the same shell/theme/plugins, Windows Terminal styled to match
(Catppuccin Mocha + Nerd Font), and an optional themed PowerShell profile.

## Included

- `install-arch-wsl.ps1` — installs Arch Linux on WSL2
- `setup-arch-shell.sh` — run *inside* Arch: zsh, oh-my-zsh, `agnosterzak` theme, plugins, CLI tools
- `dotfiles/zshrc.template` — the `.zshrc` that gets installed (clean rebuild, no secrets or local paths)
- `install-windows-terminal-theme.ps1` — adds a themed "Arch (mirror)" profile to Windows Terminal
- `install-powershell-theme.ps1` — *(bonus)* oh-my-posh + PSReadLine/Terminal-Icons/PSFzf/posh-git, themed `$PROFILE`
- `common.ps1` — shared helpers (settings.json read/write/backup, color scheme injection)

## Requirements

- WSL2 enabled (already is on this machine)
- Windows Terminal installed
- Internet access (font, packages, plugin/theme repos, oh-my-posh, PS modules)
- JetBrainsMono Nerd Font Mono — installed by `..\install-hyprwin.ps1`. Run that
  first if you haven't (`-NoFontInstall`/`-ForceFontInstall` apply there too).

## Install — in order

WSL can't launch a distro it just installed in the same terminal session, so
this can't be one script. Run these in sequence:

**1. Install Arch on WSL2** (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\install-arch-wsl.ps1
```

Close and reopen Windows Terminal when it tells you to, then launch Arch and
create your Linux user when prompted:

```powershell
wsl -d archlinux
```

**2. Set up the shell** (from inside Arch, using the auto-mounted Windows drive):

```bash
bash /mnt/c/Users/<you>/Documents/ClaudeSpace/hyprwin/terminal-mirror/setup-arch-shell.sh
```

Then close the WSL session and reopen it (`wsl -d archlinux`) to start zsh.

**3. Theme Windows Terminal** (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows-terminal-theme.ps1
# add -SetAsDefault to make the Arch (mirror) profile open by default
```

**4. (Bonus) Theme PowerShell** (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\install-powershell-theme.ps1
```

PowerShell 7's Windows Terminal profile gets a per-machine GUID that can't be
predicted from a script — the script themes `$PROFILE` and the built-in
"Windows PowerShell" entry, then prints a one-time manual step (Settings →
PowerShell → Appearance) to pick "Catppuccin Mocha" / the Nerd Font for your
PowerShell 7 profile too.

## Verification checklist

- [ ] After step 1: `wsl -d archlinux` launches into a working Arch shell
- [ ] After step 2: prompt shows the `agnosterzak` theme; `lsd`/`fzf`/`fastfetch`
      work; typing shows autosuggestions and syntax highlighting
- [ ] After step 3: the "Arch (mirror)" profile in Windows Terminal renders
      Catppuccin Mocha colors and Nerd Font glyphs correctly
- [ ] After step 4: a new PowerShell session loads the oh-my-posh prompt and
      icon-decorated `ls`/`dir` output without errors

## Notes

- All scripts back up files before changing them (`<file>.backup-<timestamp>`)
  and are safe to re-run.
- `install-windows-terminal-theme.ps1` creates a new "Arch (mirror)" profile
  rather than overriding Windows Terminal's auto-generated WSL profile —
  dynamically generated profiles use per-machine GUIDs that can't be targeted
  reliably from a script.
- `dotfiles/zshrc.template` is a clean rebuild of the relevant prompt/plugin/alias
  setup, not a copy of any real `.zshrc` — it intentionally carries no machine
  paths, exports, or tokens.
