if command -v node >/dev/null 2>&1; then
    export NPM_CONFIG_PREFIX="${HOME}/.npm-global"
    export PATH="${HOME}/.npm-global/bin:${PATH}"
fi
