# Holodor — handoff to fusor (2026-08-02)

**Holodor is a SteamOS-faithful Arch Linux for the AYN Odin 3** — Valve's Holo Core aarch64
userland + ROCKNIX SM8750 kernel, built on a fork of the pocknix-os harness.
Repo: `github.com/transentient/holodor` (PRIVATE, branch `holodor-main`).

## STATUS: IT WORKS. Steam Big Picture runs on the device.

First hardware boot succeeded 2026-08-02 after a long debugging marathon. The Odin 3 is
currently running Holodor from SD, signed in to Steam, controls working.

## Where things are (on fusor)

| Path | What |
|---|---|
| `~/projects/holodor` | the repo (git, pushes to GitHub over SSH) |
| `~/projects/rocknix-distribution` | ROCKNIX `next` checkout (`~/projects/distribution` symlinks to it — the harness's default `DISTRIBUTION_DIR`) |
| `~/projects/holodor/build/localrepo/sm8750/` | **34 prebuilt packages — DO NOT DELETE.** ~20h of native aarch64 compilation (mesa 26.1.5, gamescope, FEX, proton-cachyos, kernel) |
| `~/projects/holodor/build/image/sm8750/pocknix-sm8750-sd.img` | the v0.2 SD image (16.4 GB) |
| `~/projects/holodor/build/rootfs` | v0.2 rootfs (with a FINALIZED Steam seed) |

Build host prerequisites already installed: `qemu-user-static` + `qemu-user-static-binfmt`
(aarch64 binfmt registered), `arch-install-scripts`, `gptfdisk`, `dosfstools`, `parted`, `screen`.

## The live device

- `ssh root@192.168.1.15` — key already installed, password `pocknix`
- Hostname `holodor`; sshd runs even when the Steam session fails (invaluable for debugging)
- **The card in the device is a hand-patched one-off**, not reproducible. v0.2 is the clean one.

## IMMEDIATE NEXT STEP

The v0.2 image was built BEFORE the InputPlumber fixes (commit `d35cd93`), so **it would ship
with dead controls**. Rebuild before flashing:

```sh
cd ~/projects/holodor
# HOLODOR_SKIP_PKGPHASE=1 TRUSTS the localrepo: if a commit touched ANY package source
# (packages/**, devices/*/packages/**), force-rebuild those packages FIRST or the image
# silently ships the stale build (this bit us: d35cd93 + 8c73543 bumped pocknix-bsp-sm8750
# and pocknix-steam, and a skip-phase rebuild shipped dead controls + the -r 120 wedge):
#   sudo env DEVICE=sm8750 bash scripts/build-packages.sh <pkg>...
sudo env DEVICE=sm8750 HOLODOR_SKIP_PKGPHASE=1 HOLODOR_RESUME=1 bash scripts/build-image.sh
sudo env DEVICE=sm8750 SD_TIMEZONE=Asia/Tokyo bash scripts/build-sd-image.sh
# then flash natively (fusor has real USB — no Windows/usbipd nonsense):
lsblk    # confirm the card device FIRST
sudo dd if=build/image/sm8750/pocknix-sm8750-sd.img of=/dev/sdX bs=4M conv=fsync status=progress
```

## Hard-won knowledge (do not relearn)

1. **Firmware**: SM8750 vendor blobs (WCN7860 wifi, qca BT, adsp/cdsp, audio, vpu) live in
   `ROCKNIX/extra-firmware` under `SM8750/**` — NOT upstream linux-firmware. The A830 GPU
   firmware (`qcom/gen80000_*`) IS upstream. Both are now fetched at build time (`99f9015`,
   `443d879`) and the build DIES if anything is missing.
2. **Display**: `gamescope -r 120` wedged the DPU command-mode pipeline — ppdone/vblank
   timeouts ×118 per boot. Dropping `-r` entirely = zero errors. Never reintroduce it.
3. **Steam seed**: the build-time bake could never finish on an SD-card build host (900s AND
   3600s timeouts) and shipping the unfinalized seed caused an **infinite update loop**
   (download → apply → fail → revert). On fusor's NVMe the bake COMPLETES. A half-baked seed
   is far worse than no seed.
4. **libibus**: the aarch64 `steamwebhelper` needs `libibus-1.0.so.5` via a RELATIVE symlink at
   `$STEAM/lib/aarch64-linux-gnu/`. If it dangles, steamwebhelper crash-loops every 10s and the
   screen stays black while Steam otherwise looks healthy.
5. **Ownership**: never touch `/home/deck` as root. 126 root-owned files there made every Steam
   update fail to apply. `chown -R deck:deck /home/deck` fixed it.
6. **InputPlumber**: composite configs gate on the devicetree model string (`AYN Odin 3`) — the
   upstream list has RP6/Odin 2 only. AYN labels buttons Nintendo-style, so the capability map
   swaps the South/East *source* codes.
7. **Codecs**: `libav*` ship in the `bins_codecs_*` VZ packages, not the main client. VZ =
   LZMA_ALONE, 7-byte header, crc32+usize in the last 10 bytes.
8. **Rootfs must never be copied between hosts without root**: a user-level rsync/scp drops
   every root-only file (/etc/shadow!) and re-owns everything to the copying user — the
   transferred v0.2 rootfs AND build chroot were both corrupt this way. build-sd-image.sh
   now fails fast on it. Rootfs + build chroot are cheap to regenerate from build/cache +
   build/localrepo; only those caches are worth transferring.
9. **Arch hosts: qemu binfmt needs the C flag** for setuid binaries (sudo) inside aarch64
   chroots — Arch registers qemu-aarch64 with `FP` only and makepkg's `sudo pacman` fails
   with "effective uid is not 0" (looks like nosuid, isn't). Fixed on fusor via
   /etc/binfmt.d/qemu-aarch64-static.conf (flags POCF); documented in fusor's NOTES.md.

## Known-open work

- Rebuild + flash v0.2 (above), then verify a clean boot needs NO manual fixes
- Suspend/resume, audio output, X/Y button orientation (A/B confirmed fixed)
- USB-C host mode: a USB keyboard was not detected at the fallback shell — worth fixing, and a
  USB gadget serial/network console would make future debugging far easier
- Change default passwords (root/deck = `pocknix`)
- pocknix-os has NO LICENSE — filed `shuuri-labs/pocknix-os#21`. Holodor stays PRIVATE until
  upstream picks one.

## Credits / license posture

GPL-2.0-or-later fork of pocknix-os (pending their license), crediting ROCKNIX, Armada,
Valve/Collabora (Holo Core), FEX, and Mesa/Turnip.
