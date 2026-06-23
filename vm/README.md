# VM Testing

x86_64 QEMU/KVM VM for exploring and testing the custom image before upgrading
the live system. On Linux the VM uses KVM hardware acceleration so it's fast
enough to run a full desktop session.

## One-time setup

```bash
just vm-download-iso   # download Fedora Silverblue ISO (~2.5 GB)
just vm-create         # create 60 GB disk + initialise vm/OVMF_VARS.fd (EFI store)
just vm-install        # open QEMU window — follow the Anaconda installer
```

When Anaconda finishes and asks you to reboot, **close the QEMU window instead**
— the ISO is not mounted on the next boot so you won't re-enter the installer.

## Daily workflow

```bash
just vm-run            # boot the installed VM (GTK window, KVM accelerated)
just vm-ssh            # SSH into the running VM from a separate terminal
```

SSH is forwarded on `localhost:2222` — no password needed if you accepted the
default key setup during install.

## Switching to your custom image

**From GHCR (requires the image to be public):**

```bash
# inside the VM
sudo bootc switch ghcr.io/iwillig/dev-linux:latest
sudo reboot
```

**From a locally-built image (no push required):**

```bash
# from the host — VM must be running
just vm-load-local

# then inside the VM
sudo bootc switch --transport containers-storage localhost/dev-linux:local
sudo reboot
```

## Before upgrading — snapshot first

Take a snapshot before switching to a new image so you can roll back instantly
without reinstalling:

```bash
just vm-snapshot before-upgrade   # save current state
just vm-run                        # boot and test the new image
```

If something is wrong, restore and try again:

```bash
just vm-restore before-upgrade
just vm-run
```

List all snapshots:

```bash
just vm-snapshots
```

## Skip the Anaconda install — use the CI-built qcow2

If a release has already been built, you can download a pre-installed disk
image and skip the Anaconda step entirely:

```bash
just download-release   # downloads and decompresses the qcow2 into vm/
just vm-run             # boot straight into your image
```

## Notes

- Disk images (`*.qcow2`, `*.iso`, `OVMF_VARS.fd`) are gitignored — back them
  up manually if you care about the installed state.
- The QEMU window captures your mouse; press `Ctrl+Alt+G` to release it.
- The VM's SSH port is `2222` on localhost (configurable via `VM_SSH_PORT` in
  the justfile).
