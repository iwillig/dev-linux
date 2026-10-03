# shellcheck shell=bash
# Pi's installer (https://pi.dev/install.sh) prefers ~/.local/bin for its
# managed, self-updating install when that directory is on PATH.
if [ -d "${HOME}/.local/bin" ]; then
    export PATH="${HOME}/.local/bin:${PATH}"
fi
