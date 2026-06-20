# ── Sway — minimal Wayland tiling WM alongside GNOME ─────────────────────────
# All packages are in standard Fedora repos — no COPR needed.
# GDM auto-detects /usr/share/wayland-sessions/sway.desktop (installed by the
# sway package) and offers it as a login session choice — no display manager
# changes needed.  All tools are session-scoped and do not conflict with GNOME.
#
# NOTE: Hyprland was evaluated but its solopasha COPR packages currently fail
# on bluefin-dx because they require libdisplay-info.so.2 while the base image
# ships libdisplay-info-0.3.0 (.so.3), which mutter also depends on.  Revisit
# once the COPR rebuilds against .so.3.
RUN dnf5 install -y \
    sway \
    swaylock \
    swaybg \
    swayidle \
    xdg-desktop-portal-wlr \
    waybar \
    wofi \
    mako \
    && dnf5 clean all \
    && ostree container commit
