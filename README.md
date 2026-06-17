# dev-linux

A custom Fedora Atomic image based on [Bluefin DX](https://projectbluefin.io/), optimized for development on a Framework Intel laptop.

## What's included

- **Base**: `ghcr.io/ublue-os/bluefin-dx:stable` — GNOME + dev tooling baseline (Fedora 44)
- **Shell**: fish (default), with starship prompt
- **Terminal**: Alacritty, Zellij
- **Editors**: Emacs, Neovim
- **Dev tools**: gcc/make/gdb (Development Tools group), pandoc, aspell, fd, bat, eza, zoxide, fzf, jq, yq, httpie, zellij
- **Browsers**: Firefox, Nyxt
- **Apps**: 1Password
- **Fonts**: JetBrains Mono Nerd Font, Cascadia Code, Inter — with tuned subpixel rendering
- **Framework extras**: thermald, fprintd (fingerprint reader), powertop

---

## Installing on the Framework laptop

The recommended path uses a custom installer ISO built from your exact OCI image via [`bootc-image-builder`](https://github.com/osbuild/bootc-image-builder). You boot from it and the Anaconda installer puts your image directly onto disk — no internet required on the target machine after that.

### Step 1 — Make the GHCR image public

Go to **github.com/iwillig/dev-linux → Packages → dev-linux → Package settings → Change visibility → Public**.

This is required for `bootc-image-builder` and `bootc` to pull the image without credentials.

### Step 2 — Build and download the installer ISO

Tag a release to trigger the CI build:

```bash
just release v0.1.0
```

CI will build the OCI image, run `bootc-image-builder` to produce a custom Anaconda ISO, and attach it to the GitHub Release. Once the run finishes (~15 min), download it:

```bash
just download-release   # saves to vm/
```

Or download manually from the [Releases page](https://github.com/iwillig/dev-linux/releases).

### Step 3 — Write the ISO to USB

```bash
# Find your USB device
just usb-list

# Write the ISO (replace /dev/disk4 with your USB device)
sudo dd if=vm/dev-linux-v0.1.0.iso of=/dev/disk4 bs=4m status=progress
```

> On macOS use `just usb-write /dev/disk4` — it handles unmounting and uses the raw device automatically.

### Step 4 — Install

1. Plug USB into Framework, power on, press F12 for boot menu
2. Select the USB drive
3. Follow the Anaconda installer — partition as you like, set username/password
4. Reboot — you're running your custom image

### Step 5 — Updating after installation

Whenever you add or change packages, push to `main`, wait for CI to finish, then on the Framework:

```bash
sudo bootc update
sudo reboot
```

`bootc update` pulls only the changed layers from GHCR (fast after the first pull), stages the new image alongside the running one, and activates it on next boot. Your data in `/home` is untouched.

To check whether an update is available without applying it:

```bash
sudo bootc status
```

To roll back to the previous image if something goes wrong:

```bash
sudo bootc rollback
sudo reboot
```

---

## Alternative: bootc switch from stock Silverblue

If you already have Fedora Silverblue installed, you can rebase to this image directly without a custom ISO:

```bash
sudo bootc switch ghcr.io/iwillig/dev-linux:latest
sudo reboot
```

After the initial switch, future updates work the same way:

```bash
sudo bootc update
sudo reboot
```

---

## Local development (macOS)

Requires `podman` (`brew install podman`) and `just`.

```bash
just build          # build amd64 image locally via podman
just shell          # open bash inside the built image
just check-fonts    # verify fonts installed correctly
just check-packages # list installed packages
```

---

## QEMU testing

Test the image in a VM before installing on bare metal. Downloads a stock Fedora Silverblue ISO, installs it into a QEMU disk, then you rebase to your custom image.

```bash
just vm-download-iso   # one-time: download Fedora 44 Silverblue ISO (~2.5 GB)
just vm-create         # one-time: create 60 GB disk
just vm-install        # one-time: boot installer, follow Anaconda
just vm-run            # start the VM
just vm-ssh            # SSH into the running VM

# Inside the VM, switch to your image:
sudo bootc switch ghcr.io/iwillig/dev-linux:latest
sudo reboot
```

To test a locally-built image without pushing to GHCR:

```bash
just vm-snapshot          # save a rollback point
just vm-load-local        # push local image into VM via SSH
# Inside VM:
sudo bootc switch --transport oci docker://localhost/dev-linux:local
sudo reboot
```

### Alternatively: use the CI-built qcow2

Skip the Silverblue install step entirely by downloading the pre-built qcow2 from a release:

```bash
just download-release   # downloads and decompresses the qcow2 into vm/
just vm-run             # boot straight into your image
```

---

## Releasing

```bash
just release v0.2.0
```

This tags the commit and pushes the tag. GitHub Actions then:
1. Builds the OCI image and pushes it to `ghcr.io/iwillig/dev-linux:latest`
2. Runs `bootc-image-builder` to produce `dev-linux-v0.2.0.iso` and `dev-linux-v0.2.0.qcow2.zst`
3. Attaches both to a GitHub Release

You can also trigger the disk image build manually from the Actions tab (useful for testing the ISO without tagging).
