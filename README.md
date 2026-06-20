# dev-linux

A custom Fedora Atomic image based on [Bluefin
DX](https://projectbluefin.io/), optimized for development on a
Framework Intel laptop.

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

The recommended path uses a custom installer ISO built from your exact
OCI image via
[`bootc-image-builder`](https://github.com/osbuild/bootc-image-builder). You
boot from it and the Anaconda installer puts your image directly onto
disk — no internet required on the target machine after that.

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

`bootc update` pulls only the changed layers from GHCR (fast after the
first pull), stages the new image alongside the running one, and
activates it on next boot. Your data in `/home` is untouched.

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

If you already have Fedora Silverblue installed, you can rebase to
this image directly without a custom ISO:

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

## Local development

Requires `podman` and `just`. Works on both Linux (native) and macOS.

```bash
just build          # build amd64 image locally via podman
just shell          # open bash inside the built image
just test           # smoke-test: verify key commands and fonts
just check-fonts    # list installed fonts
just check-packages # list installed packages
```

### Testing on Linux (live system)

Since you're already running dev-linux, the fastest feedback loop is to build
locally and switch the running system to your changes:

```bash
just local-switch   # build → export → sudo bootc switch (staged, not yet active)
sudo reboot         # activate the new image
```

If something breaks after rebooting:

```bash
sudo bootc rollback
sudo reboot
```

`bootc` keeps the previous image around, so rollback is instant.

### Testing on macOS

Requires `podman` (`brew install podman`) and `just`.

---

## QEMU testing

Test the image in an isolated VM before installing on bare metal. Downloads a
stock Fedora Silverblue ISO, installs it into a QEMU disk, then you rebase to
your custom image. On Linux the VM uses KVM hardware acceleration; on macOS it
falls back to TCG software emulation.

```bash
just vm-download-iso   # one-time: download Fedora 44 Silverblue ISO (~2.5 GB)
just vm-create         # one-time: create 60 GB disk (+ init OVMF_VARS on Linux)
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
sudo bootc switch --transport containers-storage localhost/dev-linux:local
sudo reboot
```

### Alternatively: use the CI-built qcow2

Skip the Silverblue install step entirely by downloading the pre-built
qcow2 from a release:

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

---

## Displays

The laptop panel (`eDP-1`) auto-disables whenever the ViewSonic XG3220
external monitor is connected, so the external monitor is the only active
display rather than extending/mirroring — handled by `kanshi`
(`/etc/kanshi/config`), matched by monitor make/model/serial rather than
connector name so it keeps working regardless of which port/dock it's
plugged into.

- **sway**: automatic via kanshi. Manual override: `mod+shift+i` (laptop
  only) / `mod+shift+o` (external only), or `kanshictl switch laptop|external`
  from a terminal.
- **GNOME**: kanshi requires the wlr-output-management protocol, which
  mutter doesn't implement, so switching there is manual — use Settings →
  Displays, or `gnome-monitor-config list` / `set` from a terminal.

To support a different external monitor, update the `output "..."` match
string in `/etc/kanshi/config` — get the exact make/model/serial via
`swaymsg -t get_outputs`.

---

## Known issues

### Zoom screen sharing fails on sway ("No supported targets specified")

Sharing a screen or window in Zoom silently fails to start. The portal logs
the error:

```
journalctl --user -u xdg-desktop-portal-wlr
[ERROR] - wlroots: No supported targets specified
```

This is an upstream bug in `xdg-desktop-portal-wlr` 0.8.1/0.8.2 (the version
shipped in Fedora 44):
[emersion/xdg-desktop-portal-wlr#379](https://github.com/emersion/xdg-desktop-portal-wlr/issues/379).
`SelectSources` defaults its requested type-mask to `0` instead of `MONITOR`
when the caller omits the `types` option, so the type intersection is always
empty and the call fails — regardless of whether you pick a monitor or a
window in the share dialog. It is not specific to Zoom; any client that omits
`types` (per the portal spec, which allows this) hits it.

As of 2026-06-20, the latest upstream release (0.8.3) does not include a fix.
A one-line patch is posted on the issue and has been community-confirmed to
work, but isn't merged yet. Revisit once upstream merges a fix or Fedora
picks up a patched build — until then, no workaround is applied in this
image.
