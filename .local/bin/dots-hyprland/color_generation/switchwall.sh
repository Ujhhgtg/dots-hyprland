#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$XDG_STATE_HOME/dots-hyprland"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"
DOTFILES_SCRIPT_DIR="$HOME/.local/bin/dots-hyprland"

switch() {
	imgpath=$1

	if [ "$imgpath" == '' ]; then
		echo 'Invalid path'
		exit 0
	fi

	mkdir -p $STATE_DIR
	ln -sf $imgpath $STATE_DIR/wallpaper
	imgpath=$STATE_DIR/wallpaper

	read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
	cursorposx=$(hyprctl cursorpos -j | jq '.x' 2>/dev/null) || cursorposx=960
	cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
	cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
	cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
	cursorposy_inverted=$((screensizey - cursorposy))

	swww img "$imgpath" --transition-step 100 --transition-fps 120 \
		--transition-type grow --transition-angle 30 --transition-duration 1 \
		--transition-pos "$cursorposx, $cursorposy_inverted"
}

if [ "$1" == "--noswitch" ]; then
	imgpath=$(swww query | awk -F 'image: ' '{print $2}')
elif [[ "$1" ]]; then
	switch "$1"
else
    cd "$(xdg-user-dir PICTURES)" || cd $HOME
	switch "$(yad --width 1200 --height 800 --file --add-preview --large-preview --title='Choose wallpaper')"
fi

# Generate colors for ags
"$DOTFILES_SCRIPT_DIR"/color_generation/colorgen.sh "${imgpath}" --apply #--smart
