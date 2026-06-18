IMAGE        := "localhost/dev-linux:local"
VM_DISK      := "vm/dev-linux.qcow2"
VM_ISO       := "vm/fedora-silverblue.iso"
FEDORA_VER   := "44"
VM_RAM       := "8G"
VM_CPUS      := "8"
VM_SSH_PORT  := "2222"

# ── Image build ───────────────────────────────────────────────────────────────

# Build the image locally (amd64 — matches Framework target)
build:
    podman build --platform linux/amd64 -t {{IMAGE}} .

# Full rebuild without cache
build-fresh:
    podman build --platform linux/amd64 --no-cache -t {{IMAGE}} .

# Open a shell in the built image to inspect it
shell:
    podman run --rm -it --platform linux/amd64 {{IMAGE}} bash

# Verify fonts landed correctly
check-fonts:
    podman run --rm --platform linux/amd64 {{IMAGE}} fc-list | grep -i "JetBrains\|Nerd\|Inter\|Cascadia"

# List installed packages
check-packages:
    podman run --rm --platform linux/amd64 {{IMAGE}} rpm -qa | sort

# Download ShellSpec into vendor/shellspec/ (one-time setup)
test-install:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p vendor/shellspec
    curl -fsSL https://github.com/shellspec/shellspec/raw/master/install.sh \
        | sh -s -- --yes --prefix "${PWD}/vendor/shellspec"
    echo "ShellSpec installed to vendor/shellspec/"

# Run the full ShellSpec suite inside the built image
test: build
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f vendor/shellspec/lib/shellspec/shellspec ]]; then
        just test-install
    fi
    podman run --rm --platform linux/amd64 \
        --workdir /workspace \
        -v "$(pwd)/spec:/workspace/spec:ro,z" \
        -v "$(pwd)/.shellspec:/workspace/.shellspec:ro,z" \
        -v "$(pwd)/vendor/shellspec:/shellspec:ro,z" \
        {{IMAGE}} \
        /shellspec/lib/shellspec/shellspec

# Run specs against the already-built image (skip the podman build step)
test-fast:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f vendor/shellspec/lib/shellspec/shellspec ]]; then
        just test-install
    fi
    podman run --rm --platform linux/amd64 \
        --workdir /workspace \
        -v "$(pwd)/spec:/workspace/spec:ro,z" \
        -v "$(pwd)/.shellspec:/workspace/.shellspec:ro,z" \
        -v "$(pwd)/vendor/shellspec:/shellspec:ro,z" \
        {{IMAGE}} \
        /shellspec/lib/shellspec/shellspec

# Pull latest upstream to check for updates
check-upstream:
    podman pull --platform linux/amd64 ghcr.io/ublue-os/bluefin-dx:stable

# Remove local build artifacts
clean:
    podman rmi {{IMAGE}} 2>/dev/null || true

# ── Live system testing (Linux only) ─────────────────────────────────────────

# Build and stage the local image as the next boot target.
# After rebooting you're running your changes. Roll back with:
#   sudo bootc rollback && sudo reboot
local-switch: build
    @echo "Exporting image to /tmp/dev-linux-oci ..."
    podman save --format oci-dir -o /tmp/dev-linux-oci {{IMAGE}}
    @echo "Staging local image for next boot..."
    sudo bootc switch --transport oci /tmp/dev-linux-oci
    @echo ""
    @echo "Run: sudo reboot"
    @echo "To roll back: sudo bootc rollback && sudo reboot"

# ── Framework installation ────────────────────────────────────────────────────

# List block devices to find your USB drive
usb-list:
    #!/usr/bin/env bash
    if [[ "$(uname)" == "Darwin" ]]; then
        diskutil list external
    else
        lsblk -d -o NAME,SIZE,MODEL
    fi

# Write an ISO to a USB drive
# Usage: just usb-write /dev/sdb   (Linux)
#        just usb-write /dev/disk4  (macOS)
usb-write DEVICE:
    #!/usr/bin/env bash
    set -euo pipefail
    ISO=$(ls vm/*.iso 2>/dev/null | head -1)
    if [[ -z "$ISO" ]]; then
        echo "No ISO found in vm/ — run: just download-release"
        exit 1
    fi
    echo ""
    echo "  ISO:    $ISO"
    echo "  Target: {{DEVICE}}"
    echo ""
    echo "WARNING: ALL DATA ON {{DEVICE}} WILL BE PERMANENTLY DESTROYED."
    read -p "  Type 'yes' to continue: " confirm
    [[ "$confirm" == "yes" ]] || { echo "Aborted."; exit 1; }
    if [[ "$(uname)" == "Darwin" ]]; then
        diskutil unmountDisk {{DEVICE}}
        _dev="{{DEVICE}}"
        RAW="${_dev/disk/rdisk}"
        sudo dd if="$ISO" of="$RAW" bs=4m
    else
        sudo dd if="$ISO" of={{DEVICE}} bs=4M status=progress conv=fsync
    fi
    sync
    echo "Done."

# ── Release ───────────────────────────────────────────────────────────────────

# Tag a release and trigger the disk image build in CI
# Usage: just release v0.1.0
release VERSION:
    git tag -a {{VERSION}} -m "Release {{VERSION}}"
    git push origin {{VERSION}}
    @echo "Tagged {{VERSION}} — GitHub Actions will build the qcow2 and ISO."
    @echo "Track progress: gh run watch"

# Download the latest release artifacts (qcow2 + ISO) from GitHub
download-release:
    gh release download --pattern "*.qcow2.zst" --dir vm/
    gh release download --pattern "*.iso" --dir vm/
    @echo "Decompressing qcow2..."
    zstd -d vm/*.qcow2.zst -o {{VM_DISK}}

# ── VM management (QEMU x86_64 — macOS and Linux) ───────────────────────────
#
# Linux uses KVM (-accel kvm) and GTK display; OVMF requires a writable VARS
# copy at vm/OVMF_VARS.fd (created automatically by vm-create).
# macOS (Apple Silicon) uses TCG software emulation and the Cocoa display.

# Download the Fedora Silverblue x86_64 ISO
vm-download-iso:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p vm
    BASE="https://download.fedoraproject.org/pub/fedora/linux/releases/{{FEDORA_VER}}/Silverblue/x86_64/iso"
    ISO=$(curl -sL "$BASE/" | grep -oE 'Fedora-Silverblue[^"]+\.iso' | head -1)
    if [[ -z "$ISO" ]]; then
        echo "Error: could not find ISO at $BASE/"
        exit 1
    fi
    echo "Downloading $ISO ..."
    curl -L --progress-bar -o {{VM_ISO}} "$BASE/$ISO"
    echo "Saved to {{VM_ISO}}"

# Create a fresh 60GB VM disk (also initialises OVMF_VARS.fd on Linux)
vm-create:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p vm
    qemu-img create -f qcow2 {{VM_DISK}} 60G
    echo "Created {{VM_DISK}}"
    if [[ "$(uname)" != "Darwin" ]] && [[ ! -f vm/OVMF_VARS.fd ]]; then
        cp /usr/share/edk2/ovmf/OVMF_VARS.fd vm/OVMF_VARS.fd
        echo "Initialised vm/OVMF_VARS.fd (EFI variable store)"
    fi

# Boot the Fedora installer (run once to install the OS into the disk)
vm-install:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "$(uname)" == "Darwin" ]]; then
        OVMF_ARGS="-drive if=pflash,format=raw,file=/opt/homebrew/share/qemu/edk2-x86_64-code.fd,readonly=on"
        ACCEL_ARGS="-accel tcg,thread=multi -cpu qemu64"
        DISPLAY_ARGS="-display cocoa,show-cursor=on"
    else
        OVMF_ARGS="-drive if=pflash,format=raw,file=/usr/share/edk2/ovmf/OVMF_CODE.fd,readonly=on -drive if=pflash,format=raw,file=vm/OVMF_VARS.fd"
        ACCEL_ARGS="-accel kvm -cpu host"
        DISPLAY_ARGS="-display gtk"
    fi
    qemu-system-x86_64 \
        $ACCEL_ARGS \
        -machine q35 \
        -m {{VM_RAM}} \
        -smp {{VM_CPUS}} \
        $OVMF_ARGS \
        -drive file={{VM_DISK}},if=virtio,cache=writeback \
        -cdrom {{VM_ISO}} \
        -boot d \
        -netdev user,id=net0,hostfwd=tcp::{{VM_SSH_PORT}}-:22 \
        -device virtio-net-pci,netdev=net0 \
        -device virtio-vga \
        $DISPLAY_ARGS \
        -usb -device usb-tablet

# Boot the installed VM (normal run, no ISO)
vm-run:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "$(uname)" == "Darwin" ]]; then
        OVMF_ARGS="-drive if=pflash,format=raw,file=/opt/homebrew/share/qemu/edk2-x86_64-code.fd,readonly=on"
        ACCEL_ARGS="-accel tcg,thread=multi -cpu qemu64"
        DISPLAY_ARGS="-display cocoa,show-cursor=on"
    else
        OVMF_ARGS="-drive if=pflash,format=raw,file=/usr/share/edk2/ovmf/OVMF_CODE.fd,readonly=on -drive if=pflash,format=raw,file=vm/OVMF_VARS.fd"
        ACCEL_ARGS="-accel kvm -cpu host"
        DISPLAY_ARGS="-display gtk"
    fi
    qemu-system-x86_64 \
        $ACCEL_ARGS \
        -machine q35 \
        -m {{VM_RAM}} \
        -smp {{VM_CPUS}} \
        $OVMF_ARGS \
        -drive file={{VM_DISK}},if=virtio,cache=writeback \
        -netdev user,id=net0,hostfwd=tcp::{{VM_SSH_PORT}}-:22 \
        -device virtio-net-pci,netdev=net0 \
        -device virtio-vga \
        $DISPLAY_ARGS \
        -usb -device usb-tablet

# SSH into the running VM
vm-ssh:
    ssh -p {{VM_SSH_PORT}} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null localhost

# Push the locally-built podman image into the VM and switch to it
# The VM must be running. After it loads, run inside the VM:
#   sudo bootc switch --transport containers-storage localhost/dev-linux:local
vm-load-local:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Saving image to tarball..."
    podman save {{IMAGE}} -o /tmp/dev-linux-local.tar
    echo "Copying to VM..."
    scp -P {{VM_SSH_PORT}} -o StrictHostKeyChecking=no /tmp/dev-linux-local.tar localhost:/tmp/
    echo "Loading into podman on VM..."
    ssh -p {{VM_SSH_PORT}} -o StrictHostKeyChecking=no localhost \
        "podman load -i /tmp/dev-linux-local.tar && rm /tmp/dev-linux-local.tar"
    rm /tmp/dev-linux-local.tar
    echo ""
    echo "Inside the VM run:"
    echo "  sudo bootc switch --transport containers-storage {{IMAGE}}"
    echo "  sudo reboot"

# Take a snapshot of the VM disk (before switching images — easy rollback)
vm-snapshot NAME="before-switch":
    qemu-img snapshot -c {{NAME}} {{VM_DISK}}
    echo "Snapshot '{{NAME}}' created"

# List snapshots
vm-snapshots:
    qemu-img snapshot -l {{VM_DISK}}

# Restore a snapshot
vm-restore NAME="before-switch":
    qemu-img snapshot -a {{NAME}} {{VM_DISK}}
    echo "Restored to snapshot '{{NAME}}'"
