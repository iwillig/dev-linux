# ── Better font rendering ─────────────────────────────────────────────────────
COPY config/files/ /

# Enable first-boot services
# pi-coding-agent-install is a --global user unit: it installs Pi
# (https://pi.dev) per-user into ~/.local/bin on first login via the
# upstream installer, rather than a root-owned copy in the image, so `pi
# update` can keep it current without rebuilding the image.
RUN systemctl enable install-1password.service && \
    systemctl --global enable pi-coding-agent-install.service && \
    ostree container commit
