IMAGE        := "localhost/dev-linux:local"
VM_DISK      := "vm/dev-linux.qcow2"
VM_ISO       := "vm/fedora-silverblue.iso"
OVMF         := "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
FEDORA_VER   := "42"
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

# Pull latest upstream to check for updates
check-upstream:
    podman pull --platform linux/amd64 ghcr.io/ublue-os/bluefin-dx:stable

# Remove local build artifacts
clean:
    podman rmi {{IMAGE}} 2>/dev/null || true

# ── Framework installation ────────────────────────────────────────────────────

# List disks to find your USB device before writing
usb-list:
    diskutil list external

# Write the Fedora Silverblue ISO to a USB drive (macOS)
# Usage: just usb-write /dev/disk4
# Find your USB device first with: just usb-list
usb-write DEVICE:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f "{{VM_ISO}}" ]]; then
        echo "ISO not found at {{VM_ISO}}"
        echo "Run: just vm-download-iso"
        exit 1
    fi
    echo ""
    echo "  ISO:    {{VM_ISO}}"
    echo "  Target: {{DEVICE}}"
    echo ""
    echo "WARNING: ALL DATA ON {{DEVICE}} WILL BE PERMANENTLY DESTROYED."
    read -p "  Type 'yes' to continue: " confirm
    [[ "$confirm" == "yes" ]] || { echo "Aborted."; exit 1; }
    echo "Unmounting {{DEVICE}}..."
    diskutil unmountDisk {{DEVICE}}
    RAW="${{DEVICE/disk/rdisk}}"
    echo "Writing ISO to $RAW (this will take a few minutes)..."
    sudo dd if={{VM_ISO}} of=$RAW bs=4m
    sync
    echo ""
    echo "Done. Eject the USB and boot your Framework from it."
    echo "After installing Fedora Silverblue, run the switch command:"
    echo ""
    echo "  sudo bootc switch ghcr.io/iwillig/dev-linux:latest"

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

# ── VM management (QEMU x86_64 on Apple Silicon) ─────────────────────────────

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

# Create a fresh 60GB VM disk
vm-create:
    mkdir -p vm
    qemu-img create -f qcow2 {{VM_DISK}} 60G
    echo "Created {{VM_DISK}}"

# Boot the Fedora installer (run once to install the OS into the disk)
vm-install:
    qemu-system-x86_64 \
        -accel tcg,thread=multi \
        -cpu qemu64 \
        -machine q35 \
        -m {{VM_RAM}} \
        -smp {{VM_CPUS}} \
        -drive if=pflash,format=raw,file={{OVMF}},readonly=on \
        -drive file={{VM_DISK}},if=virtio,cache=writeback \
        -cdrom {{VM_ISO}} \
        -boot d \
        -netdev user,id=net0,hostfwd=tcp::{{VM_SSH_PORT}}-:22 \
        -device virtio-net-pci,netdev=net0 \
        -device virtio-vga \
        -display cocoa,show-cursor=on \
        -usb -device usb-tablet

# Boot the installed VM (normal run, no ISO)
vm-run:
    qemu-system-x86_64 \
        -accel tcg,thread=multi \
        -cpu qemu64 \
        -machine q35 \
        -m {{VM_RAM}} \
        -smp {{VM_CPUS}} \
        -drive if=pflash,format=raw,file={{OVMF}},readonly=on \
        -drive file={{VM_DISK}},if=virtio,cache=writeback \
        -netdev user,id=net0,hostfwd=tcp::{{VM_SSH_PORT}}-:22 \
        -device virtio-net-pci,netdev=net0 \
        -device virtio-vga \
        -display cocoa,show-cursor=on \
        -usb -device usb-tablet

# SSH into the running VM
vm-ssh:
    ssh -p {{VM_SSH_PORT}} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null localhost

# Load the locally-built podman image into the VM via SSH
# The VM must be running. Run 'just vm-ssh' first to get the password.
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
    echo "Done — inside the VM run: sudo bootc switch --transport oci docker://{{IMAGE}}"

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
