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
