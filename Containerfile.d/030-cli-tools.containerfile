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

# whis CLI (https://whis.ink/cli): voice-to-text, separate from the Flatpak
# desktop app; not in Fedora repos. Release asset name embeds the version, so
# the latest/download static-filename trick (used above) doesn't apply here —
# resolve the tag first, as with lazygit.
RUN WHIS_VERSION=$(curl -sL "https://api.github.com/repos/frankdierolf/whis/releases/latest" | \
      jq -r '.tag_name') && \
    curl -fsSL "https://github.com/frankdierolf/whis/releases/download/${WHIS_VERSION}/whis-${WHIS_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /usr/bin whis && \
    ostree container commit

# trufflehog: secret scanner for git repos, filesystems, and live sources
# (https://github.com/trufflesecurity/trufflehog); not in Fedora repos.
# Asset name embeds the version without the leading "v", as with lazygit.
RUN TRUFFLEHOG_VERSION=$(curl -sL "https://api.github.com/repos/trufflesecurity/trufflehog/releases/latest" | \
      jq -r '.tag_name') && \
    curl -fsSL "https://github.com/trufflesecurity/trufflehog/releases/download/${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION#v}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/bin trufflehog && \
    ostree container commit
