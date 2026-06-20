# generated — edit Containerfile.d/*.containerfile instead
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

# starship: not in Fedora repos; /usr/local/bin doesn't exist in ostree images
RUN curl -fsSL \
    "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /usr/bin starship && \
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
    python3-mapnik \
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
    && dnf5 clean all \
    && systemctl --global enable kanshi.service \
    && ostree container commit
# ── Nord / Nordic GTK theme ───────────────────────────────────────────────────
# Papirus-Dark is the canonical icon set for Nord setups; available in Fedora repos.
RUN dnf5 install -y papirus-icon-theme \
    && dnf5 clean all \
    && ostree container commit

# Nordic GTK theme (EliverLara) — install GTK3 variant first, then GTK4 on top
# so /usr/share/themes/Nordic/ ends up with gtk-3.0/ and gtk-4.0/ sub-trees.
RUN NORDIC_VERSION="v2.2.0" && \
    mkdir -p /usr/share/themes && \
    curl -fsSL "https://github.com/EliverLara/Nordic/releases/download/${NORDIC_VERSION}/Nordic.tar.xz" \
    | tar -xJ -C /usr/share/themes && \
    curl -fsSL "https://github.com/EliverLara/Nordic/releases/download/${NORDIC_VERSION}/Nordic-v40.tar.xz" \
    | tar -xJ -C /usr/share/themes && \
    ostree container commit
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
# ── llama.cpp — local LLM inference ──────────────────────────────────────────
# Uses official pre-built Linux x86_64 binaries (CPU backend).
# The tarball ships its own libggml*/libllama* .so files with RUNPATH=$ORIGIN,
# so binaries find their libs via /usr/lib/llama.cpp/ without needing ldconfig.
# Symlinks expose llama-cli, llama-server, and llama-bench on PATH.
#
# To switch to GPU acceleration, replace the asset selector with:
#   ubuntu-vulkan-x64.tar.gz  (Vulkan — Intel Iris Xe / Arc supported)
#   ubuntu-sycl-fp16-x64      (SYCL — Intel GPU, requires oneAPI runtime)
RUN LLAMA_URL=$(curl -sL "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest" | \
      jq -r '.assets[] | select(.name | test("bin-ubuntu-x64\\.tar\\.gz$")) | .browser_download_url') && \
    mkdir -p /usr/lib/llama.cpp && \
    curl -fsSL "$LLAMA_URL" | tar -xz --strip-components=1 -C /usr/lib/llama.cpp && \
    ln -sf /usr/lib/llama.cpp/llama-cli    /usr/bin/llama-cli    && \
    ln -sf /usr/lib/llama.cpp/llama-server /usr/bin/llama-server && \
    ln -sf /usr/lib/llama.cpp/llama-bench  /usr/bin/llama-bench  && \
    ostree container commit
