# dev-linux

A custom Fedora Atomic image based on [Bluefin DX](https://projectbluefin.io/), optimized for development on a Framework Intel laptop.

## What's included

- **Base**: `ghcr.io/ublue-os/bluefin-dx:43` — GNOME + dev tooling baseline (Fedora 43)
- **Tiling WM**: Hyprland (Wayland-native) as an additional session alongside GNOME
- **Fonts**: JetBrains Mono Nerd Font, Cascadia Code, Inter — with tuned subpixel rendering
- **Framework extras**: thermald, fprintd (fingerprint reader), powertop
- **Dev tools**: neovim, tmux, ripgrep, bat, eza, zoxide, fzf, starship, jq, yq

## Installing on the Framework laptop

### Step 1 — Make the GHCR image public

Go to **github.com/iwillig/dev-linux → Packages → dev-linux → Package settings → Change visibility → Public**.

This allows `bootc switch` to pull the image without credentials on the Framework.

### Step 2 — Write the installer USB

You need the Fedora Silverblue ISO and a USB drive (8GB+).

```bash
# Download the ISO if you haven't already (~2.5GB)
just vm-download-iso

# Find your USB device
just usb-list

# Write the ISO (replace /dev/disk4 with your USB device)
just usb-write /dev/disk4
```

### Step 3 — Install Fedora Silverblue on the Framework

1. Plug USB into Framework, power on, press F12 for boot menu
2. Select the USB drive
3. Follow the Anaconda installer — partition as you like, set a username/password
4. Reboot into the freshly installed Fedora Silverblue

### Step 4 — Switch to your custom image

On first boot, open a terminal and run:

```bash
sudo bootc switch ghcr.io/iwillig/dev-linux:latest
sudo reboot
```

That's it. After reboot you're running your custom image with Hyprland available as a session.

### Staying up to date

Push changes to `main` → CI rebuilds the image → on the Framework run:

```bash
sudo bootc update
sudo reboot
```

---

## Local development (macOS)

Requires `podman` (installed via `brew install podman`) and `just`.

```bash
just build        # build amd64 image locally via podman
just shell        # open bash inside the built image
just check-fonts  # verify fonts installed correctly
just check-packages
```

## QEMU testing

Test the image in a VM before installing on bare metal:

```bash
just vm-download-iso   # one-time: download Fedora Silverblue ISO
just vm-create         # one-time: create 60GB disk
just vm-install        # one-time: install Fedora inside the VM

just vm-run            # boot the VM
just vm-ssh            # SSH into the running VM

# Inside the VM, switch to your image:
sudo bootc switch ghcr.io/iwillig/dev-linux:latest
sudo reboot
```

## Hyprland

After switching, select **Hyprland** from the session picker on the login screen.
Config lives in `~/.config/hypr/hyprland.conf` — create this on first login.
See [wiki.hyprland.org](https://wiki.hyprland.org/) for config reference.
