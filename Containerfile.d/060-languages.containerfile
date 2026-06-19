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
