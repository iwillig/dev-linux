# Nyxt browser — pinned AppImage; /opt is a symlink in ostree images.
ARG NYXT_VERSION=5.0.0
RUN mkdir -p /usr/lib/nyxt && \
    curl -fsSL \
      "https://github.com/atlas-engineer/nyxt/releases/download/${NYXT_VERSION}/Nyxt-${NYXT_VERSION}-x86_64.AppImage" \
      -o /usr/lib/nyxt/Nyxt-x86_64.AppImage && \
    chmod +x /usr/lib/nyxt/Nyxt-x86_64.AppImage && \
    ln -sf /usr/lib/nyxt/Nyxt-x86_64.AppImage /usr/bin/nyxt && \
    ostree container commit
