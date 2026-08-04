# Holodor — handoff to fusor (2026-08-02)

**Holodor is a SteamOS-faithful Arch Linux for the AYN Odin 3** — Valve's Holo Core aarch64
userland + ROCKNIX SM8750 kernel, built on a fork of the pocknix-os harness.
Repo: `github.com/transentient/holodor` (PRIVATE, branch `holodor-main`).

## STATUS: v0.2 BOOTS CLEAN — Steam, controls, Wi-Fi, zero manual surgery.

2026-08-02 (evening): the reproducible v0.2 image boots straight into Steam on hardware —
GPU firmware loads from the boot-image initramfs (593512e killed the probe-vs-mount race),
InputPlumber controls correct out of the box, Wi-Fi preseeded, seed finalized (no update
loop), root auto-expansion verified (done from fusor; on-device growpart still missing).
CAVEAT: the current SanDisk Ultra 128GB card is DYING (stuck flash blocks that silently
ignore writes — recurring fsck damage in /usr/share/icons/breeze). Treat it as a test mule;
flash the next card (Cliff's older 32GB/64GB candidates — ABL-check them in System Stats
FIRST) from the current repo + build tree, which now contain every fix.

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

Flash a healthy card (the SanDisk is dying): ABL-check the candidate card first (insert in
Odin, VOL- menu, System Stats must show the SD), then build + flash. 32GB minimum (image is
16.4GB), 64GB+ if games go on it. The current build tree already has every fix; a plain
rebuild works:

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

## STATUS UPDATE 2026-08-03: FIRST FULLY-CLEAN BOOT — 64GB card is the daily driver

Everything-image flashed to the 64GB card (byte-for-byte readback-verified), first boot:
GPU/controls/sound/Wi-Fi/auto-expand(57G)/scx_lavd ALL working, zero surgery. SanDisk
retired. First-login note: the OOBE client update + unsynced clock caused a one-time
~40min "stuck at login / connection problem" episode (update-apply I/O starves sshd; the
bogus RTC date breaks Steam TLS until NTP syncs) — resolved by one power-cycle; the next
boot verified clean (bootstrap_log: Nothing to do; clock synced).

## INTERNAL INSTALL DONE 2026-08-04 — awaiting the SD-pull ceremony

`pocknix-install-internal --userdata-gib 32` ran clean from the SD system (sleep-inhibited):
Android userdata reset to 34GB, sda18=ROCKNIX FAT (KERNEL md5-verified), sda19=HOLODOR_ROOT
433GB ext4, fstab correct, hardened bsp-common-2/sdcard-automount-5 chroot-installed into
the clone. NEXT: power off -> REMOVE SD -> power on (internal boots; SD left in = two
HOLODOR_ROOT partlabels = ambiguous root). SD card = bootable rescue, store it safe.
FIRST INTERNAL BOOT: verify UFS speed feel, then check whether the Steam client now offers
the newly-public Lepton/FEX tools (went public on Steam 2026-08-01..03).

## Known-open work

- ~~growpart / scx_lavd~~ RESTORED (2026-08-03 overnight): ALARM binaries via localrepo —
  cloud-guest-utils direct, scx-scheds via packages/scx-scheds (repackaged: ALARM's
  'libgcc' dep → Holo's 'gcc-libs'). plymouth still commented (cosmetic, needs theme work)
- **Audio WORKS** (2026-08-03): bsp 0.2.0-3 ships ROCKNIX's Odin 3 UCM (speaker verified
  on hardware). Headphones jack-detect profile untested. Games launched before the fix
  attach to the dummy sink — restart the game for sound
- Retire the dying SanDisk; flash a fresh card (above) and re-verify clean boot end-to-end.
  **The current build/image/sm8750/pocknix-sm8750-sd.img (built overnight 08-03) has
  EVERYTHING: fw-initramfs KERNEL, audio UCM, growpart, scx_lavd, Wi-Fi preseed** —
  spot-check verified; just dd it
- The localrepo kernel package still carries the OLD pocknix-build-bootimg (no fw
  initramfs) — fusor can't rebuild it (no kernel out tree); the rootfs copy is patched,
  but rebuild linux-pocknix-sm8750 with the fixed hook at the next kernel build
- Suspend/resume CORE WORKS (2026-08-04: manual, in-game, and rtcwake all verified; RTC is
  VOLATILE — resets to epoch on cold boot, clock-seed fix 75cf663). Two residuals:
  (a) InputPlumber controls occasionally dead after resume — re-grab race; workaround:
  suspend/resume again; harden sleep-post with a delay/retry. (b) ONE unexplained hard
  wedge after an idle-triggered suspend (2026-08-03 19:01, journal ends at 'PM: suspend
  entry') — watch for recurrence, bisect with pm_test if it does
- Vanquish (x86 UE action game via FEX+Proton+DXVK/Turnip) RUNS WELL per Cliff (2026-08-04)
- X/Y button orientation in-game (A/B + audio confirmed fixed)
- UI "slightly glitchy" (Cliff, 08-03, otherwise snappy) — characterize: visual artifacts
  (gamescope/Turnip) vs hitches (sched/IO)?
- First-boot clock: RTC comes up with a bogus date → Steam TLS fails until NTP syncs
  (the "connection problem" at first login). Consider seeding the clock at boot from the
  build timestamp (e.g. a tmpfiles/service touch-file floor) so TLS works pre-NTP
- Small unit cleanups: sdcard-mount.sh tries to mount the boot SD's own root partition
  (add a root-disk guard); disable systemd-networkd-wait-online (we run NetworkManager)
- USB-C host mode: a USB keyboard was not detected at the fallback shell — worth fixing, and a
  USB gadget serial/network console would make future debugging far easier
- Change default passwords (root/deck = `pocknix`)
- Dev images bake Cliff's Wi-Fi from `config/local/*.nmconnection` (gitignored) — REMOVE
  for any polished/shared image (empty `config/local/`); users get Wi-Fi via OOBE
- pocknix-os has NO LICENSE — filed `shuuri-labs/pocknix-os#21`. Holodor stays PRIVATE until
  upstream picks one.
- **Lepton watch** (Valve's Waydroid-based Android layer, "Proton for Android"): went live
  2026-08-01 as a background Steam runtime + Steamworks Android depots (APK/OBB, APK as
  launch executable) ahead of the Steam Frame launch — the Frame runs our same Holo-family
  aarch64 SteamOS, and Android games would run NATIVELY on the Odin 3 (no FEX tax).
  NOT pullable yet (2026-08-03): no package in any Holo snapshot (mash-20251118.3 is still
  the newest), no store page / public depot — delivery is via the Steam client itself.
  Our kernel is already ready (binder+binderfs on for Waydroid; MEMFD covers ashmem).
  WATCH: (a) new `mash-*` snapshots at holo-packages.steamos.cloud (a Holo bump is a
  whole-base upgrade — deliberate change, HOLO_MIRROR pin in config/pocknix.conf),
  (b) a lepton runtime/depot appearing in the arm64 client (SteamDB, or on-device under
  ~/.local/share/Steam), (c) whether Valve gates it to Frame hardware.

## Credits / license posture

GPL-2.0-or-later fork of pocknix-os (pending their license), crediting ROCKNIX, Armada,
Valve/Collabora (Holo Core), FEX, and Mesa/Turnip.
