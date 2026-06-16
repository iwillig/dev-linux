ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin-dx"
# Pinned to Fedora 43: gts is also fc44, so we use the explicit tag.
# libdisplay-info-0.2.0 on fc43 provides .so.2 needed by the solopasha COPR's
# aquamarine. Switch to "stable" once the COPR rebuilds for fc44.
ARG TAG="43"

FROM ${BASE_IMAGE}:${TAG}

# ── Hyprland COPR ────────────────────────────────────────────────────────────
RUN FEDORA_VER=$(. /etc/os-release && echo "$VERSION_ID") && \
    curl -fsSL \
      "https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/repo/fedora-${FEDORA_VER}/solopasha-hyprland-fedora-${FEDORA_VER}.repo" \
      -o /etc/yum.repos.d/solopasha-hyprland.repo && \
    ostree container commit

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
    lxqt-policykit \
    qt5ct \
    qt6ct \
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
