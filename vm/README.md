# VM Testing

x86_64 QEMU VM for testing the custom image before installing on the Framework laptop.

## One-time setup

```bash
just vm-download-iso   # download Fedora Silverblue ISO (~2.5GB)
just vm-create         # create 60GB disk image
just vm-install        # boot installer — install Fedora inside the VM
```

After Fedora is installed in the VM, the ISO is no longer needed for normal runs.

## Daily workflow

```bash
just vm-run            # boot the installed VM
just vm-ssh            # SSH into the running VM (in a separate terminal)
```

## Switching to your custom image (inside the VM)

Once the VM is running and your image is pushed to GHCR:

```bash
# Inside the VM:
sudo bootc switch ghcr.io/iwillig/dev-linux:latest
sudo reboot
```

Or to test a locally-built image before pushing, from your Mac:

```bash
just vm-load-local     # load the local podman image into the VM
# Then inside the VM:
sudo bootc switch --transport oci docker://localhost/dev-linux:local
```

## Notes

- The VM uses QEMU TCG (software emulation) because Apple Silicon cannot
  hardware-accelerate x86_64 guests. It's slower than native but sufficient
  for testing package installs, bootc switching, and Hyprland sessions.
- Disk images are gitignored (they're large). Keep backups manually.
- VM console: the QEMU window. Serial console also available via the monitor.
