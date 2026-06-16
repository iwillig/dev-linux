ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin-dx"
ARG TAG="stable"

FROM ${BASE_IMAGE}:${TAG}

# ── Framework laptop & Intel-specific ────────────────────────────────────────
RUN rpm-ostree install \
    thermald \
    fprintd \
    fprintd-pam \
    powertop \
    && ostree container commit

# ── Developer tooling ────────────────────────────────────────────────────────
RUN rpm-ostree install \
    emacs \
    neovim \
    tmux \
    fd-find \
    bat \
    eza \
    zoxide \
    fzf \
    jq \
    yq \
    httpie \
    && ostree container commit

# starship: not in Fedora repos; /usr/local/bin doesn't exist in ostree images
RUN curl -fsSL \
    "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/bin starship && \
    ostree container commit

# ── Fonts ─────────────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    jetbrains-mono-fonts \
    cascadia-code-fonts \
    google-noto-emoji-fonts \
    && ostree container commit

RUN mkdir -p /usr/share/fonts/inter && \
    INTER_URL=$(curl -sL "https://api.github.com/repos/rsms/inter/releases/latest" | \
      jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url') && \
    curl -fsSL "$INTER_URL" -o /tmp/inter.zip && \
    unzip -q /tmp/inter.zip -d /tmp/inter-extracted && \
    find /tmp/inter-extracted -name "*.otf" -exec cp {} /usr/share/fonts/inter/ \; && \
    rm -rf /tmp/inter.zip /tmp/inter-extracted && \
    fc-cache -f && \
    ostree container commit

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
