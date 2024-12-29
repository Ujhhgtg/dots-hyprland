#!/usr/bin/env bash

DOTFILES_SCRIPT_DIR="$HOME/.local/bin/dots-hyprland"

# unused by shell
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$(xdg-user-dir PICTURES)"
"$DOTFILES_SCRIPT_DIR"/color_generation/switchwall.sh "$(fd . $(xdg-user-dir PICTURES)/wallpapers/ -e .png -e .jpg -e .svg | xargs shuf -n1 -e)"
