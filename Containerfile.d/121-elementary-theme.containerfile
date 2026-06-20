# ── elementary GTK theme ──────────────────────────────────────────────────────
# elementary-icon-theme is packaged natively in Fedora, but the GTK stylesheet
# itself isn't (only Arch/Ubuntu package it) — built from source per upstream's
# own instructions (meson + sassc). Upstream (8.2.2+) only ships accent-color
# variants now, no plain "io.elementary.stylesheet" theme; slate is the
# neutral/gray variant, closest to the classic elementary look.
RUN dnf5 install -y elementary-icon-theme meson ninja-build sassc \
    && dnf5 clean all \
    && ostree container commit

RUN STYLESHEET_VERSION="8.2.2" && \
    curl -fsSL "https://github.com/elementary/stylesheet/archive/refs/tags/${STYLESHEET_VERSION}.tar.gz" \
    | tar -xz && \
    cd "stylesheet-${STYLESHEET_VERSION}" && \
    meson setup build --prefix=/usr && \
    ninja -C build install && \
    cd .. && rm -rf "stylesheet-${STYLESHEET_VERSION}" && \
    dnf5 remove -y meson ninja-build sassc \
    && dnf5 clean all \
    && ostree container commit
