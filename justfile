IMAGE := "localhost/dev-linux:local"

# Build the image locally with podman
build:
    podman build -t {{IMAGE}} .

# Build without layer cache (full rebuild)
build-fresh:
    podman build --no-cache -t {{IMAGE}} .

# Open a shell in the built image to inspect it
shell:
    podman run --rm -it {{IMAGE}} bash

# Test font config inside the built image
check-fonts:
    podman run --rm -it {{IMAGE}} fc-list | grep -i "JetBrains\|Nerd\|Inter\|Cascadia"

# List installed packages in the built image
check-packages:
    podman run --rm -it {{IMAGE}} rpm -qa | sort

# Switch a running Fedora Atomic / bootc system to this image
# Run this inside a VM, not on your host
switch:
    sudo bootc switch --transport oci docker://{{IMAGE}}

# Pull the latest upstream bluefin-dx to check for updates
check-upstream:
    podman pull ghcr.io/ublue-os/bluefin-dx:stable

# Clean up local build artifacts
clean:
    podman rmi {{IMAGE}} 2>/dev/null || true
