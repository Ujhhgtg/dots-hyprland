#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE_DIR="$XDG_CACHE_HOME/dots-hyprland"
STATE_DIR="$XDG_STATE_HOME/dots-hyprland"
DOTFILES_SCRIPT_DIR="$HOME/.local/bin/dots-hyprland"

term_alpha=100 # set this to < 100 make all your terminals transparent
mkdir -p "$CACHE_DIR"/user/generated
cd "$DOTFILES_SCRIPT_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

transparentize() {
  local hex="$1"
  local alpha="$2"
  local red green blue

  red=$((16#${hex:1:2}))
  green=$((16#${hex:3:2}))
  blue=$((16#${hex:5:2}))

  printf 'rgba(%d, %d, %d, %.2f)\n' "$red" "$green" "$blue" "$alpha"
}

get_light_dark() {
    lightdark=""
    if [ ! -f "$STATE_DIR/user/colormode.txt" ]; then
        echo "" > "$STATE_DIR/user/colormode.txt"
    else
        lightdark=$(sed -n '1p' "$STATE_DIR/user/colormode.txt")
    fi
    echo "$lightdark"
}

apply_fuzzel() {
    # Check if scripts/templates/fuzzel/fuzzel.ini exists
    if [ ! -f "templates/fuzzel/fuzzel.ini" ]; then
        echo "Template file not found for Fuzzel. Skipping."
        return
    fi
    # Copy template
    mkdir -p "$CACHE_DIR"/user/generated/fuzzel
    cp "templates/fuzzel/fuzzel.ini" "$CACHE_DIR"/user/generated/fuzzel/fuzzel.ini
    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/${colorvalues[$i]#\#}/g" "$CACHE_DIR"/user/generated/fuzzel/fuzzel.ini
    done

    cp "$CACHE_DIR"/user/generated/fuzzel/fuzzel.ini "$XDG_CONFIG_HOME"/fuzzel/fuzzel.ini
}

apply_term() {
    # Check if terminal escape sequence template exists
    if [ ! -f "templates/terminal/sequences.txt" ]; then
        echo "Template file not found for Terminal. Skipping."
        return
    fi
    # Copy template
    mkdir -p "$CACHE_DIR"/user/generated/terminal
    cp "templates/terminal/sequences.txt" "$CACHE_DIR"/user/generated/terminal/sequences.txt
    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$CACHE_DIR"/user/generated/terminal/sequences.txt
    done

    sed -i "s/\$alpha/$term_alpha/g" "$CACHE_DIR/user/generated/terminal/sequences.txt"

    for file in /dev/pts/*; do
      if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
        cat "$CACHE_DIR"/user/generated/terminal/sequences.txt > "$file"
      fi
    done
}

apply_hyprland() {
    # Check if scripts/templates/hypr/hyprland/colors.conf exists
    if [ ! -f "templates/hypr/hyprland/colors.conf" ]; then
        echo "Template file not found for Hyprland colors. Skipping."
        return
    fi
    # Copy template
    mkdir -p "$CACHE_DIR"/user/generated/hypr/hyprland
    cp "templates/hypr/hyprland/colors.conf" "$CACHE_DIR"/user/generated/hypr/hyprland/colors.conf
    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/${colorvalues[$i]#\#}/g" "$CACHE_DIR"/user/generated/hypr/hyprland/colors.conf
    done

    cp "$CACHE_DIR"/user/generated/hypr/hyprland/colors.conf "$XDG_CONFIG_HOME"/hypr/hyprland/colors.conf
}

apply_hyprlock() {
    # Check if scripts/templates/hypr/hyprlock.conf exists
    if [ ! -f "templates/hypr/hyprlock.conf" ]; then
        echo "Template file not found for hyprlock. Skipping."
        return
    fi
    # Copy template
    mkdir -p "$CACHE_DIR"/user/generated/hypr/
    cp "templates/hypr/hyprlock.conf" "$CACHE_DIR"/user/generated/hypr/hyprlock.conf
    # Apply colors
    # sed -i "s/{{ SWWW_WALL }}/${wallpath_png}/g" "$CACHE_DIR"/user/generated/hypr/hyprlock.conf
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/${colorvalues[$i]#\#}/g" "$CACHE_DIR"/user/generated/hypr/hyprlock.conf
    done

    cp "$CACHE_DIR"/user/generated/hypr/hyprlock.conf "$XDG_CONFIG_HOME"/hypr/hyprlock.conf
}

apply_lightdark() {
    lightdark=$(get_light_dark)
    if [ "$lightdark" = "light" ]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    fi
}

apply_gtk() { # Using gradience-cli
    usegradience=$(sed -n '4p' "$STATE_DIR/user/colormode.txt")
    if [[ "$usegradience" = "nogradience" ]]; then
        rm "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
        rm "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"
        return
    fi

    # Copy template
    mkdir -p "$CACHE_DIR"/user/generated/gradience
    cp "templates/gradience/preset.json" "$CACHE_DIR"/user/generated/gradience/preset.json

    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/${colorvalues[$i]}/g" "$CACHE_DIR"/user/generated/gradience/preset.json
    done

    mkdir -p "$XDG_CONFIG_HOME/presets" # create gradience presets folder
    gradience-cli apply -p "$CACHE_DIR"/user/generated/gradience/preset.json --gtk both

    # set GTK theme manually as Gradience defaults to light adw-gtk3
    # (which is unreadable when broken when you use dark mode)
    lightdark=$(get_light_dark)
    if [ "$lightdark" = "light" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    else
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    fi
}

apply_ags() {
    ags run-js "handleStyles(false);"
    ags run-js 'openColorScheme.value = true; Utils.timeout(3000, () => openColorScheme.value = false);'
}


colornames=$(cat $STATE_DIR/scss/_material.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/scss/_material.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=( $colornames ) # Array of color names
colorvalues=( $colorstrings ) # Array of color values

apply_ags &
apply_hyprland &
apply_hyprlock &
apply_lightdark &
apply_gtk &
apply_fuzzel &
apply_term &
