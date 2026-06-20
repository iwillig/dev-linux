# ── llama.cpp — local LLM inference ──────────────────────────────────────────
# Uses official pre-built Linux x86_64 binaries (CPU backend).
# The tarball ships its own libggml*/libllama* .so files with RUNPATH=$ORIGIN,
# so binaries find their libs via /usr/lib/llama.cpp/ without needing ldconfig.
# Symlinks expose llama-cli, llama-server, and llama-bench on PATH.
#
# To switch to GPU acceleration, replace the asset selector with:
#   ubuntu-vulkan-x64.tar.gz  (Vulkan — Intel Iris Xe / Arc supported)
#   ubuntu-sycl-fp16-x64      (SYCL — Intel GPU, requires oneAPI runtime)
RUN LLAMA_URL=$(curl -sL "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest" | \
      jq -r '.assets[] | select(.name | test("bin-ubuntu-x64\\.tar\\.gz$")) | .browser_download_url') && \
    mkdir -p /usr/lib/llama.cpp && \
    curl -fsSL "$LLAMA_URL" | tar -xz --strip-components=1 -C /usr/lib/llama.cpp && \
    ln -sf /usr/lib/llama.cpp/llama-cli    /usr/bin/llama-cli    && \
    ln -sf /usr/lib/llama.cpp/llama-server /usr/bin/llama-server && \
    ln -sf /usr/lib/llama.cpp/llama-bench  /usr/bin/llama-bench  && \
    ostree container commit
