# dev-linux

A custom Fedora Atomic image based on [Bluefin DX](https://projectbluefin.io/), optimized for development on a Framework Intel laptop.

## What's included

- **Base**: `ghcr.io/ublue-os/bluefin-dx:stable` — GNOME + dev tooling baseline
- **Tiling WM**: Hyprland (Wayland-native) as an additional session alongside GNOME
- **Fonts**: JetBrains Mono Nerd Font, Cascadia Code, Inter — with tuned subpixel rendering
- **Framework extras**: thermald, fprintd (fingerprint reader), powertop
- **Dev tools**: neovim, tmux, ripgrep, bat, eza, zoxide, fzf, starship, jq, yq

## Using the built image

The image is published to GHCR on every push to `main`:

```bash
# Switch your Fedora Atomic system to this image
sudo bootc switch ghcr.io/iwillig/dev-linux:latest

# Or rebase with rpm-ostree (older systems)
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/iwillig/dev-linux:latest
```

## Local development

Requires `podman` and `just`.

```bash
just build        # build the image locally
just shell        # inspect the built image
just check-fonts  # verify fonts are installed correctly
just switch       # switch a running VM to this image (run inside the VM)
```

## Testing before installing

1. Create a Fedora Atomic VM (Fedora Silverblue ISO works)
2. Build locally: `just build`
3. Inside the VM: `sudo bootc switch --transport oci docker://localhost/dev-linux:local`
4. Reboot and select the Hyprland session

## Hyprland

After switching, select **Hyprland** from the session picker on the login screen. Hyprland config lives in `~/.config/hypr/hyprland.conf` — you'll want to create this on first boot. See [hyprland.org/wiki](https://wiki.hyprland.org/) for config reference.
