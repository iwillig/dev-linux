# Pi's installer (https://pi.dev/install.sh) prefers ~/.local/bin for its
# managed, self-updating install when that directory is on PATH.
if test -d "$HOME/.local/bin"
    fish_add_path "$HOME/.local/bin"
end
