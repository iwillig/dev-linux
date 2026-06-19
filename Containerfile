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
    python3 \
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
    ripgrep \
    btop \
    tldr \
    && ostree container commit

# GitHub CLI — official RPM repo; not in Fedora repos
RUN curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo \
      -o /etc/yum.repos.d/gh-cli.repo && \
    dnf5 install -y gh && \
    dnf5 clean all && \
    ostree container commit

# Set fish as the default shell for new users (read by Anaconda at install time)
RUN sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd && \
    ostree container commit

# zellij: not in Fedora 44 repos, install musl binary from GitHub releases
RUN curl -fsSL \
    "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/bin zellij && \
    ostree container commit

# lazygit: git TUI, not in Fedora repos
RUN LAZYGIT_VERSION=$(curl -sL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \
      jq -r '.tag_name') && \
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz" \
    | tar -xz -C /usr/bin lazygit && \
    ostree container commit

# fastfetch: tarball is fastfetch-linux-amd64/{usr/bin,usr/share,...}; strip the top dir
RUN curl -fsSL \
    "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz" \
    | tar -xz --strip-components=1 -C / && \
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

# Pi coding agent — use dnf5 (not rpm-ostree) so nodejs is immediately available
# for the subsequent npm call within the same RUN step
RUN dnf5 install -y nodejs && \
    dnf5 clean all && \
    npm install -g --prefix /usr --ignore-scripts @earendil-works/pi-coding-agent && \
    ostree container commit

# TypeScript toolchain — compiler + LSP server for Emacs/Neovim editor integration
RUN npm install -g --prefix /usr --ignore-scripts \
    typescript \
    typescript-language-server && \
    ostree container commit

# Claude Code CLI
RUN npm install -g --prefix /usr @anthropic-ai/claude-code && \
    ostree container commit

# Clojure — use dnf5 so java is immediately available when the installer runs;
# use --prefix /usr (ostree has no /usr/local/bin)
RUN dnf5 install -y java-25-openjdk && \
    dnf5 clean all && \
    curl -fsSL "https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh" \
      -o /tmp/clojure-install.sh && \
    chmod +x /tmp/clojure-install.sh && \
    /tmp/clojure-install.sh --prefix /usr && \
    rm /tmp/clojure-install.sh && \
    ostree container commit

# Handy — open-source push-to-talk speech-to-text; not in Fedora repos
# gtk-layer-shell is a runtime dependency missing from the handy RPM metadata
RUN dnf5 install -y gtk-layer-shell && \
    HANDY_RPM_URL=$(curl -sL "https://api.github.com/repos/cjpais/Handy/releases/latest" | \
      jq -r '.assets[] | select(.name | test("x86_64\\.rpm$")) | .browser_download_url') && \
    curl -fsSL "$HANDY_RPM_URL" -o /tmp/handy.rpm && \
    dnf5 install -y /tmp/handy.rpm && \
    dnf5 clean all && \
    rm /tmp/handy.rpm && \
    ostree container commit

# ── Spatial / GIS tooling ─────────────────────────────────────────────────────
RUN rpm-ostree install \
    gdal \
    gdal-devel \
    gdal-libs \
    python3-gdal \
    mapnik \
    mapnik-devel \
    qgis \
    grass \
    grass-devel \
    proj \
    proj-devel \
    geos \
    geos-devel \
    libspatialite \
    libspatialite-devel \
    spatialite-tools \
    && ostree container commit

# ── Wine ──────────────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    wine \
    winetricks \
    && ostree container commit

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
