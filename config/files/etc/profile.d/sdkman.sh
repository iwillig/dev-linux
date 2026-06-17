if [ -d /var/sdkman ]; then
    export SDKMAN_DIR=/var/sdkman
    [[ -s /var/sdkman/bin/sdkman-init.sh ]] && source /var/sdkman/bin/sdkman-init.sh
fi
