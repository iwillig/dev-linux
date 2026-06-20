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
    plantuml \
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
