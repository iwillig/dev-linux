# ── Waybar theme: mechabar ───────────────────────────────────────────────────
# https://github.com/sejjy/mechabar — pinned to a commit since upstream has no
# tags. Vendored into /etc/xdg/waybar (waybar's system-wide config fallback,
# used since no ~/.config/waybar exists). The upstream tree assumes Hyprland
# and Arch/pacman in a few places we don't want:
#   - modules/hyprland/{workspaces,window}.jsonc -> replaced with sway
#     equivalents in config/files/etc/xdg/waybar/modules/sway/ (waybar's CSS
#     selectors are compositor-agnostic, so styles/*.css need no changes)
#   - modules/hyprland/language.jsonc has no sway equivalent in waybar and
#     isn't needed (this setup uses a single fixed keyboard layout) -> dropped
#   - modules/custom/update.jsonc + scripts/update shell out to
#     checkupdates/pacman, meaningless on this bootc image -> dropped
#   - on-click/exec strings hardcode "~/.config/waybar/..." -> rewritten to
#     /etc/xdg/waybar since this is a system-wide install, not a user one
#   - power/bluetooth/network modules launch their fzf menu via "kitty -e"
#     -> rewritten to "alacritty -e" to match this image's default terminal
# Our config/files/etc/xdg/waybar/ overrides (config.jsonc, the sway modules,
# custom/distro.jsonc, theme.css/themes/nord.css, styles/fonts.css) are
# re-applied via the explicit COPY below so they win over the vendored tree
# regardless of COPY ordering in 110-config.containerfile.
RUN MECHABAR_REF="97959c73a6e62efba0b79dfaf0f8b2823377f7b9" && \
    mkdir -p /etc/xdg/waybar && \
    curl -fsSL "https://github.com/sejjy/mechabar/archive/${MECHABAR_REF}.tar.gz" \
    | tar -xz --strip-components=1 -C /etc/xdg/waybar && \
    rm -rf /etc/xdg/waybar/modules/hyprland \
           /etc/xdg/waybar/modules/custom/update.jsonc \
           /etc/xdg/waybar/scripts/update \
           /etc/xdg/waybar/install && \
    find /etc/xdg/waybar -name "*.jsonc" \
        -exec sed -i \
            -e 's|~/\.config/waybar|/etc/xdg/waybar|g' \
            -e 's|kitty -e|alacritty -e|g' \
            {} + && \
    ostree container commit

COPY config/files/etc/xdg/waybar/ /etc/xdg/waybar/
RUN ostree container commit
