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
