# ── Wine ──────────────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    wine \
    winetricks \
    && ostree container commit
