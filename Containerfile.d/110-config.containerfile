# ── Better font rendering ─────────────────────────────────────────────────────
COPY config/files/ /

# Enable first-boot services
RUN systemctl enable install-1password.service && \
    ostree container commit
