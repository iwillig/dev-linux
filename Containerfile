ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin-dx"
ARG TAG="stable"

FROM ${BASE_IMAGE}:${TAG}

# ── Hyprland & Wayland compositor stack ──────────────────────────────────────
RUN rpm-ostree install \
    hyprland \
    hyprlock \
    hyprpaper \
    hypridle \
    waybar \
    wofi \
    mako \
    xdg-desktop-portal-hyprland \
    wl-clipboard \
    grim \
    slurp \
    polkit-gnome \
    qt5ct \
    qt6ct \
    nwg-look \
    && ostree container commit

# ── Framework laptop & Intel-specific ────────────────────────────────────────
RUN rpm-ostree install \
    thermald \
    fprintd \
    fprintd-pam \
    powertop \
    && ostree container commit

# ── Developer tooling (beyond what bluefin-dx already ships) ─────────────────
RUN rpm-ostree install \
    neovim \
    tmux \
    ripgrep \
    fd-find \
    bat \
    eza \
    zoxide \
    fzf \
    starship \
    jq \
    yq \
    httpie \
    && ostree container commit

# ── Fonts ─────────────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    jetbrains-mono-fonts \
    cascadia-code-fonts \
    inter-fonts \
    google-noto-emoji-fonts \
    && ostree container commit

# Download JetBrains Mono Nerd Font (patched version, not in Fedora repos)
RUN NERD_FONT_VERSION="v3.2.1" && \
    mkdir -p /usr/share/fonts/nerd-fonts/JetBrainsMono && \
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.tar.xz" \
    | tar -xJ -C /usr/share/fonts/nerd-fonts/JetBrainsMono && \
    fc-cache -f && \
    ostree container commit

# ── Better font rendering ─────────────────────────────────────────────────────
COPY config/files/ /

RUN ostree container commit
