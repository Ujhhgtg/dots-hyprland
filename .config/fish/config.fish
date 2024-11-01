export EDITOR=nano
fish_add_path ~/.local/bin

function fish_greeting
    # hyprland dotfiles section
    if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
        cat ~/.cache/ags/user/generated/terminal/sequences.txt
    end
    # section ends

    [ -f /usr/share/autojump/autojump.fish ]; and source /usr/share/autojump/autojump.fish
    fastfetch
end

if status is-interactive
    set fish_greeting
end
