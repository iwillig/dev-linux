# ── llama.cpp — local LLM inference ──────────────────────────────────────────
# Uses official pre-built Linux x86_64 binaries (CPU backend).
# The tarball ships its own libggml*/libllama* .so files with RUNPATH=$ORIGIN,
# so binaries find their libs via /usr/lib/llama.cpp/ without needing ldconfig.
# Symlinks expose llama-cli, llama-server, and llama-bench on PATH.
#
# To switch to GPU acceleration, replace the asset selector with:
#   ubuntu-vulkan-x64.tar.gz  (Vulkan — Intel Iris Xe / Arc supported)
#   ubuntu-sycl-fp16-x64      (SYCL — Intel GPU, requires oneAPI runtime)
#
# Pinned to a specific release rather than /releases/latest: the newest tag's
# binaries can lag behind its release-notes publish (assets still uploading,
# or the upload job failed), which leaves the API's assets[] empty and the
# release-notes body pointing at a URL that 404s. Bump LLAMA_CPP_TAG by hand
# to pick up new releases once their assets are confirmed present.
ARG LLAMA_CPP_TAG=b9870
RUN LLAMA_URL=$(curl -sL "https://api.github.com/repos/ggml-org/llama.cpp/releases/tags/${LLAMA_CPP_TAG}" | \
      jq -r '.assets[] | select(.name | test("bin-ubuntu-x64\\.tar\\.gz$")) | .browser_download_url') && \
    if [ -z "$LLAMA_URL" ]; then \
      echo "ERROR: no ubuntu-x64 asset found for llama.cpp release ${LLAMA_CPP_TAG}" >&2; \
      exit 1; \
    fi && \
    mkdir -p /usr/lib/llama.cpp && \
    curl -fsSL "$LLAMA_URL" | tar -xz --strip-components=1 -C /usr/lib/llama.cpp && \
    ln -sf /usr/lib/llama.cpp/llama-cli    /usr/bin/llama-cli    && \
    ln -sf /usr/lib/llama.cpp/llama-server /usr/bin/llama-server && \
    ln -sf /usr/lib/llama.cpp/llama-bench  /usr/bin/llama-bench  && \
    ostree container commit
