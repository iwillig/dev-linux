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
