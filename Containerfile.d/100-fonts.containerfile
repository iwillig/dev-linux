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
