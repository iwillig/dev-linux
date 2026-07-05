# Homebrew — cloned to /home/linuxbrew/.linuxbrew (/home → /var/home in ostree)
# The image's /var is used to initialize a fresh install, so brew is available on first boot.
# wheel group owns the prefix so the default admin user can run brew install without sudo.
RUN mkdir -p /var/home/linuxbrew && \
    git clone --depth=1 https://github.com/Homebrew/brew /var/home/linuxbrew/.linuxbrew && \
    chown -R root:wheel /var/home/linuxbrew/.linuxbrew && \
    chmod -R g+rwX /var/home/linuxbrew/.linuxbrew && \
    ostree container commit

# opencode — installed via Homebrew tap; must run after brew is cloned above.
# eval'ing shellenv gives brew its Cellar/Homebrew.rb dependencies on PATH for
# the duration of this RUN step (brew isn't on PATH in a build shell otherwise).
# /root -> /var/roothome (symlink); pre-create it so Homebrew's Ruby code can
# resolve $HOME (Dir.mkdir on a dangling symlink target raises EEXIST).
RUN mkdir -p /var/roothome && \
    eval "$(/var/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew install anomalyco/tap/opencode && \
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
