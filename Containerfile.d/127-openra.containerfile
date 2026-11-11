# OpenRA development dependencies: https://github.com/OpenRA/OpenRA/blob/bleed/INSTALL.md#linux
# Fedora 44 ships Lua 5.1 as compat-lua-libs, not `lua = 5.1`.
RUN dnf5 install -y \
    dotnet-sdk-10.0 \
    SDL2 \
    freetype \
    compat-lua-libs \
    openal-soft \
    && dnf5 clean all \
    && ostree container commit
