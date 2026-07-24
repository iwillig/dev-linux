# Pi coding agent — use dnf5 (not rpm-ostree) so nodejs is immediately available
# for the subsequent npm call within the same RUN step
# yarnpkg is Fedora's package name for Yarn (plain "yarn" is a pre-existing cmdtest package)
RUN dnf5 install -y nodejs pnpm yarnpkg && \
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

# Rust — Fedora's packaged rustc/cargo, not rustup (upstream warns the two
# conflict on the same system). rust-src + rustfmt + clippy + rust-analyzer
# cover IDE code intelligence and linting; `cargo install` works out of the
# box for pure-Rust crates since development-tools (gcc, make) is already
# installed for crates that need to compile C dependencies.
# https://developer.fedoraproject.org/tech/languages/rust/rust-installation.html
RUN rpm-ostree install \
    rust \
    cargo \
    clippy \
    rust-src \
    rustfmt \
    rust-analyzer \
    && ostree container commit
