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
#
# sway-config-fedora must be requested explicitly — plain `dnf install sway`
# defaults to sway-config-upstream, whose vanilla config wires up foot/wmenu
# and a built-in bar instead of the waybar/wofi/mako below.
# kanshi auto-switches output profiles on hotplug (e.g. disabling eDP-1 when the
# ViewSonic XG3220 external monitor is connected) — see /etc/kanshi/config.
# gnome-monitor-config is the equivalent manual CLI for the GNOME/mutter
# session, where kanshi's wlr-output-management protocol isn't available.
# blueman and network-manager-applet ship XDG autostart entries and launch
# automatically via sway-xdg-autostart.target (no exec needed in sway config).
# gammastep (GNOME Night Light equivalent) ships a systemd user service and is
# enabled globally here so it starts with the sway session.
RUN dnf5 install -y \
    sway \
    sway-config-fedora \
    swaylock \
    swaybg \
    swayidle \
    xdg-desktop-portal-wlr \
    waybar \
    wofi \
    mako \
    kanshi \
    gnome-monitor-config \
    blueman \
    network-manager-applet \
    gammastep \
    && dnf5 clean all \
    && systemctl --global enable kanshi.service \
    && systemctl --global enable gammastep.service \
    && ostree container commit
