#!/usr/bin/env bash
# Run this from inside the Arch WSL distro (not from Windows PowerShell):
#
#   wsl -d archlinux
#   bash /mnt/c/Users/<you>/Documents/ClaudeSpace/hyprwin/terminal-mirror/setup-arch-shell.sh
#
# Safe to re-run -- each step checks whether it already did its job.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC_TEMPLATE="$SCRIPT_DIR/dotfiles/zshrc.template"
CUSTOM="$HOME/.oh-my-zsh/custom"

if [ ! -f "$ZSHRC_TEMPLATE" ]; then
  echo "Cannot find $ZSHRC_TEMPLATE -- run this script from its own directory via /mnt/c/...". >&2
  exit 1
fi

echo "==> Updating package database and installing base packages"
sudo pacman -Syu --noconfirm --needed \
  git zsh lsd fzf ncdu fastfetch base-devel

echo "==> Installing yay (AUR helper)"
if command -v yay >/dev/null 2>&1; then
  echo "yay already installed, skipping."
else
  YAY_DIR="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$YAY_DIR/yay"
  (cd "$YAY_DIR/yay" && makepkg -si --noconfirm)
  rm -rf "$YAY_DIR"
fi

echo "==> Installing oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh already installed, skipping."
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "==> Installing zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting)"
declare -A PLUGIN_REPOS=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
)
for plugin in "${!PLUGIN_REPOS[@]}"; do
  dest="$CUSTOM/plugins/$plugin"
  if [ -d "$dest" ]; then
    echo "$plugin already present, skipping."
  else
    git clone --depth=1 "${PLUGIN_REPOS[$plugin]}" "$dest"
  fi
done
# Note: 'git', 'archlinux', and 'history-substring-search' are bundled with
# oh-my-zsh already -- listing them in plugins=() is enough, no clone needed.

echo "==> Installing the agnosterzak theme"
THEME_DEST="$CUSTOM/themes/agnosterzak.zsh-theme"
if [ -f "$THEME_DEST" ]; then
  echo "agnosterzak theme already present, skipping."
else
  THEME_TMP="$(mktemp -d)"
  if git clone --depth=1 https://github.com/zakaziko99/agnosterzak-ohmyzsh-theme "$THEME_TMP/theme" >/dev/null 2>&1; then
    find "$THEME_TMP/theme" -name '*.zsh-theme' -exec cp {} "$THEME_DEST" \;
  fi
  rm -rf "$THEME_TMP"

  if [ ! -f "$THEME_DEST" ]; then
    echo "Could not fetch the agnosterzak theme automatically." >&2
    echo "Search for 'agnosterzak oh-my-zsh theme' and place the .zsh-theme file at:" >&2
    echo "  $THEME_DEST" >&2
  fi
fi

echo "==> Installing .zshrc"
cp "$ZSHRC_TEMPLATE" "$HOME/.zshrc"
echo "Wrote $HOME/.zshrc (back up your old one first if you'd customized it)."

echo "==> Setting zsh as the default shell"
CURRENT_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
ZSH_PATH="$(command -v zsh)"
if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
  echo "zsh is already the default shell."
else
  sudo chsh -s "$ZSH_PATH" "$(id -un)"
fi

echo ""
echo "Done. Close this WSL session and run 'wsl -d archlinux' again to start zsh."
