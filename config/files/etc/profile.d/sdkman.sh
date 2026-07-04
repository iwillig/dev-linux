# shellcheck shell=bash
if [ -d /var/sdkman ]; then
    export SDKMAN_DIR=/var/sdkman
    # shellcheck disable=SC1091
    [[ -s /var/sdkman/bin/sdkman-init.sh ]] && source /var/sdkman/bin/sdkman-init.sh
fi
