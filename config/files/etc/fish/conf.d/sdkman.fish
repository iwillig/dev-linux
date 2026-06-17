if test -d /var/sdkman
    set -gx SDKMAN_DIR /var/sdkman

    # Add installed SDK candidate binaries to PATH on each new shell
    for dir in /var/sdkman/candidates/*/current/bin
        if test -d $dir
            fish_add_path $dir
        end
    end
end
