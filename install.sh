#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/environment-variables
source ./scriptdata/functions
source ./scriptdata/options

#####################################################################################
if ! command -v pacman >/dev/null 2>&1; then 
  printf "\e[31m[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...\e[0m\n"
  exit 1
fi
prevent_sudo_or_root

startask () {
  printf "\e[34m[$0]: Hi there! Before we start:\n"
  printf 'This script 1. only works for ArchLinux and Arch-based distros.\n'
  printf '            2. does not handle system-level/hardware stuff like Nvidia drivers\n'
  printf "\e[31m"
  
  printf "Would you like to create a backup for \"$XDG_CONFIG_HOME\" and \"$HOME/.local/\" folders?\n[y/N]: "
  read -p " " backup_confirm
  case $backup_confirm in
    [yY][eE][sS]|[yY])
      backup_configs
      ;;
    *)
      echo "Skipping backup..."
      ;;
  esac
  

  printf '\n'
  printf 'Do you want to confirm every time before a command executes?\n'
  printf '  y = Yes, ask me before executing each of them. (DEFAULT)\n'
  printf '  n = No, just execute them automatically.\n'
  printf '  a = Abort.\n'
  read -p "====> " p
  case $p in
    n) ask=false ;;
    a) exit 1 ;;
    *) ask=true ;;
  esac
}

case $ask in
  false)sleep 0 ;;
  *)startask ;;
esac

set -e
#####################################################################################
printf "\e[36m[$0]: 1. Install packages and setup user groups & services\n\e[0m"

v paru

install-local-pkgbuild() {
	local location=$1
	local installflags=$2

	x pushd $location

  x paru -Bi $installflags .

	x popd
}

v install-local-pkgbuild "./arch-packages/ujhhgtg-hyprland-dotfiles" "--needed --noconfirm"

v sudo usermod -aG video,i2c,input "$(whoami)"
v bash -c "echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf"
v systemctl --user enable --now ydotool
v systemctl --user enable --now foot-server

#####################################################################################
printf "\e[36m[$0]: 2. Copying configuration files\e[0m\n"

# In case some folders does not exist
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

for i in $(find .config/ -mindepth 1 -maxdepth 1 -exec basename {} \;); do
  echo "[$0]: Found target: .config/$i"
  if [ -d ".config/$i" ];then v rsync -av --delete ".config/$i/" "$XDG_CONFIG_HOME/$i/"
  elif [ -f ".config/$i" ];then v rsync -av ".config/$i" "$XDG_CONFIG_HOME/$i"
  fi
done

fish -c "set --local plugins (read --null < $XDG_CONFIG_HOME/fish/fish_plugins) && curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install $plugins"

v rm -rf "$XDG_BIN_HOME/dots-hyprland/"
v ln -s ".local/bin/dots-hyprland" "$XDG_BIN_HOME/dots-hyprland"

v gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

sleep 1
try hyprctl reload

#####################################################################################
printf "\e[36m[$0]: Finished.\e[0m\n"
printf "\n"
printf "\e[36mIf you are new to Hyprland, please read\n"
printf "https://end-4.github.io/dots-hyprland-wiki/en/i-i/01setup/#post-installation\n"
printf "for hints on launching Hyprland.\e[0m\n"
printf "\n"
printf "\e[36mIf you are already running Hyprland,\e[0m\n"
printf "\e[36mPress \e[30m\e[46m Ctrl+Super+T \e[0m\e[36m to select a wallpaper\e[0m\n"
printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[0m\n"
printf "\n"
