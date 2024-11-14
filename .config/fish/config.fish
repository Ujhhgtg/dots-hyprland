export EDITOR=nano
fish_add_path ~/.local/bin

function fish_greeting
    if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
        cat ~/.cache/ags/user/generated/terminal/sequences.txt
    end

    fastfetch
end

if status is-interactive
    set fish_greeting
end
