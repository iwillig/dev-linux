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
# rpm-ostree doesn't support @group syntax in container builds; use dnf5
RUN dnf5 group install -y development-tools && dnf5 clean all && \
    ostree container commit

RUN rpm-ostree install \
    emacs \
    neovim \
    tmux \
    pandoc \
    aspell \
    aspell-en \
    fish \
    alacritty \
    firefox \
    sqlite-devel \
    stow \
    the_silver_searcher \
    rlwrap \
    xclip \
    fd-find \
    bat \
    eza \
    zoxide \
    fzf \
    jq \
    yq \
    httpie \
    && ostree container commit

# Set fish as the default shell for new users (read by Anaconda at install time)
RUN sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd && \
    ostree container commit

# zellij: not in Fedora 44 repos, install musl binary from GitHub releases
RUN curl -fsSL \
    "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/bin zellij && \
    ostree container commit

# Nyxt browser — not in Fedora repos; ships as an AppImage inside a tarball
# /opt is a symlink in ostree images; use /usr/lib instead
RUN curl -fsSL \
      "https://github.com/atlas-engineer/nyxt/releases/latest/download/Linux-Nyxt-x86_64.tar.gz" \
      -o /tmp/nyxt.tar.gz && \
    mkdir -p /usr/lib/nyxt && \
    tar -xzf /tmp/nyxt.tar.gz -C /usr/lib/nyxt && \
    chmod +x /usr/lib/nyxt/*.AppImage && \
    ln -sf /usr/lib/nyxt/Nyxt-x86_64.AppImage /usr/bin/nyxt && \
    rm /tmp/nyxt.tar.gz && \
    ostree container commit

# Homebrew — cloned to /home/linuxbrew/.linuxbrew (/home → /var/home in ostree)
# The image's /var is used to initialize a fresh install, so brew is available on first boot.
# wheel group owns the prefix so the default admin user can run brew install without sudo.
RUN mkdir -p /var/home/linuxbrew && \
    git clone --depth=1 https://github.com/Homebrew/brew /var/home/linuxbrew/.linuxbrew && \
    chown -R root:wheel /var/home/linuxbrew/.linuxbrew && \
    chmod -R g+rwX /var/home/linuxbrew/.linuxbrew && \
    ostree container commit

# SDKMAN! — installed to /var/sdkman (mutable, persists across bootc updates)
# wheel group owns the prefix so the default admin user can run sdk install without sudo.
# /root -> /var/roothome (symlink); pre-create .bashrc so the installer script can finish
# (it appends to .bashrc at the end — harmless, but errors if the file doesn't exist).
# sdkman-for-fish provides a native fish sdk function in /etc/fish/functions/sdk.fish.
RUN mkdir -p /var/roothome && \
    touch /var/roothome/.bashrc /var/roothome/.bash_profile /var/roothome/.profile && \
    curl -fsSL "https://get.sdkman.io" | SDKMAN_DIR=/var/sdkman SDKMAN_NONINTERACTIVE=true bash && \
    chown -R root:wheel /var/sdkman && \
    chmod -R g+rwX /var/sdkman && \
    mkdir -p /etc/fish/functions /etc/fish/completions && \
    curl -fsSL "https://raw.githubusercontent.com/reitzig/sdkman-for-fish/main/functions/sdk.fish" \
      -o /etc/fish/functions/sdk.fish && \
    curl -fsSL "https://raw.githubusercontent.com/reitzig/sdkman-for-fish/main/completions/sdk.fish" \
      -o /etc/fish/completions/sdk.fish && \
    ostree container commit

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

# Enable first-boot services
RUN systemctl enable install-1password.service && \
    ostree container commit
