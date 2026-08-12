# Holodor — handoff to fusor (2026-08-02)

**Holodor is a SteamOS-faithful Arch Linux for the AYN Odin 3** — Valve's Holo Core aarch64
userland + ROCKNIX SM8750 kernel, built on a fork of the pocknix-os harness.
Repo: `github.com/transentient/holodor` (PRIVATE, branch `holodor-main`).

## CURRENT STATE 2026-08-08 (read this first; sections below are chronological history)

Daily driver = internal UFS install, kernel 7.1.3-12. SUSPEND WEDGE FIXED for real:
0519 (UCSI clears USB role for charger-only Type-C partners) — the wedge only ever
hung WHILE PLUGGED IN; plugged-in rtcwake soak 4/4 clean. The 08-08 "0508 was the
wedge" conviction was a FALSE POSITIVE (module bisection confounded by cable state);
0508 stays active (via ROCKNIX 20-sm8750) as a legit controls-after-resume fix. The
rsinput sleep-guard built around that false conviction is REMOVED (bsp-common 0.1.0-11)
— it was redundant and crashed running games on resume. Charge FLAP (separate issue)
was the multi-port charger renegotiating PD, not a bad cable — use a dedicated port.
Sleep hooks now = wifi / inputplumber / sdam-debug / leds (four orthogonal, real).
Charge-limit UI SHIPS in v1 (Pocknix Control Power tab; the telemetryd charge-kick
self-heals battmgr's sticky start-threshold). GPU pair 0050/0051: turns out ROCKNIX's
20-sm8750 now carries them, so they've been ACTIVE in every recent kernel (incl. -12
which passed the plugged-in soak) — never the wedge (that was USB-role/cable). The
patches-disabled/ jail is deleted (dead dupes). Four false positives total came from
the same plugged-in-cable confound: 0508, the GPU pair, and two soak mis-reads. (rumble stack, suspend wedge FIXED —
0508 excised and field-validated), bsp-sm8750 0.2.0-7 (the wiretap-proven ASYMMETRIC
button map — A/B crossed, X/Y straight; do NOT "fix" it, read knowledge item 6),
bsp-common 0.1.0-4 (wifi + inputplumber sleep hooks; rsinput guard files REMOVED on
device — kernel fix supersedes). Audio, Wi-Fi, charge-limits, auto-expand: all working.
Buttons verified end-to-end IN-GAME. Suspend/resume clean on the new kernel.

RELEASE CANDIDATE CUT 2026-08-10: build/image/sm8750/holodor-odin3-20260810.img.zst
(7.2G, sha in same dir). Clean-from-scratch HOLODOR_RELEASE=1 build: no passwords
(Deck model), sshd off, no wifi preseed, kernel-11 + bsp-7 + LEDs/haptics — spot-check
all green. Docs INSTALL.md/README.md drafted with [VERIFY] markers. NEXT: SourceForge
project (Cliff), upload .zst+.sha256, then Cliff's SD dry-run (32GB card, no-AI tinkerer
roleplay, resolve [VERIFY] markers + fix doc bugs), then internal-install dry-run (wipes
daily driver — do LAST), then announce (Discord first). Decisions locked: baked seed v1,
SourceForge hosting, Option C security. RP6 8GB ordered as Act Two (mature sm8550, honest
floor). Art advance paid to ssalmon_px.

SUSPEND-MID-GAME 2026-08-12 — LAYER-BY-LAYER ELIMINATION DONE; CULPRIT = GAME-PROCESS-SIDE
STEAM INPUT RECEIVER (Proton/FEX steamclient plumbing). PROVEN HEALTHY across suspend: MCU
(streams 111fps clean on uart2 = 89c000.serial; bursts of 2-4 "Checksum mismatch" at
resume/probe are normal sync noise, NOT a dead link), rsinput driver, InputPlumber (native
HookSleep/HookWake + persist:true = IP survives suspend, same PID, same event nodes; persist
re-attaches source to the EXISTING composite through driver rebinds — Steam never sees a
disconnect), virtual deck pad, and STEAM ITSELF (controller.txt shows "closed after hid_read
failure" -> clean re-open -> re-reserve XInput slot 0 -> re-activation for the running appid;
Steam UI + QAM controls work perfectly while the game is deaf). ELIMINATED BY TEST: logind
vs Steam-menu-initiated suspend (both fail identically; no steamos-manager anywhere — Holo
repo lacks it), systemd user-session freeze (systemd 258 freezes user.slice on suspend;
disabled via /etc/systemd/system/systemd-suspend.service.d/no-freeze-user-sessions.conf,
verified "remain unfrozen", game receiver STILL dies — override kept anyway, it's
SteamOS-parity), controller re-enumeration (full IP restart under the running game = Steam
re-opens + re-activates, game still deaf — so the old "games never re-acquire the recreated
pad" framing was wrong; the game-side receiver is the corpse in every scenario). Dead-state
autopsy: game threads all in ntsync/futex/poll waits + one thread in skb_wait (socket read
that never delivers) — receiver waiting on a broken channel, not crashed. One observed
SPONTANEOUS recovery minutes after resume (single input burst) — periodic Steam re-activation
may eventually land; unconfirmed. NEXT SESSION LEADS: map the game's steam IPC socket (that
skb_wait fd) to its Steam-side peer across suspend; pressure-vessel/lsteamclient input path
under FEX; check whether the pending Steam CLIENT update changes behavior (Frame-era client
must solve this); ask armada/ROCKNIX if anyone sees in-GAME continuity (believed unsolved
everywhere). WIRETAP LESSON: IP exclusive-grabs sources and Steam grabs the virtual pad —
evdev taps on those nodes see NOTHING; tap Steam's x360 pad (ungrabbed) or use functional
tests (QAM/vol-up); kprobe input_event counts are contaminated by per-report no-change calls.
STAGED READY TO DEPLOY (decoupled cleanup, kills the vhci-veto/sleep-hook contraption):
inputplumber 0.77.2 pkg in localrepo + on device at /root/, yaml flipped to deck-uhid target
in repo (deck-uhid confirmed in 0.77.2 binary; tarball schema json is stale — ignore it).
Deploy ceremony: quit game -> pacman -U -> install yaml -> disable 001-inputplumber hooks +
inputplumber-suspend.service (uhid needs neither) -> restart IP -> verify buttons/glyphs in
Steam UI (asymmetric map must re-verify against the uhid target!) -> suspend soak.
DEVICE STATE at close: known-good stop/start hooks RESTORED (+x), inputplumber-suspend
disabled, persist:true live in device yaml (harmless, good), freeze override live, IP still
0.75.2 (0.77.2 staged not installed). Decky "Loading" = stale frontend injection after the
11:47 loader crash (FEX loader flakiness, predates today; unrelated to input) — fix by
loader restart, else session restart. Steam-menu jank in Hades + laggy sleep fade + the
Cyberpunk overlay jam are plausibly the SAME steamclient-in-game IPC fragility family as
the controls bug — one investigation may pay twice.

2026-08-12: SourceForge project IS SET UP (Cliff) — next release step is upload
.zst+.sha256, then the SD dry-run. Fan 'max' mode shipped (ef5d77c): CLI + daemon + QAM
selector, answers the Discord "force fan at underclock" ask; device-verified.

BUILD-SYSTEM TRAP (cost us the evening's kernel tests, 2026-08-12): `build-packages.sh
linux-pocknix-*` does NOT rebuild the kernel — the PKGBUILD merely PACKAGES the existing
`make kernel` output in build/kernel/<soc>/. Adding kernel patches and running only
build-packages ships the OLD Image with a new pkgrel (kernels "-13" and "-14" were
kernel-12 in wrappers; every on-device conclusion drawn from them is void). CORRECT
FLOW: scripts/build-kernel.sh FIRST (fresh extract + full patch stack + compile), then
build-packages. VERIFY a kernel code change landed by grepping
build/kernel/<soc>/linux-*/ for the new symbol before deploying. Kernel-15 = the first
build that really contains the ROCKNIX audio series + 0610.

HEADPHONE JACK STATUS AT 2026-08-12 CLOSE: device on kernel-17 (0610 v3: mux parks in
vendor-HSJ routing whenever no Type-C cable — verified working live; charger attached =
USB mode = jack parked, CHECK THE CHARGER before interpreting any jack test). MBHC mech
detect has NEVER verifiably fired in any constructed state; the afternoon "detect
worked" observation is unproven (see project memory 2026-08-12 night entry). NEXT: the
three-pronged intel plan in memory — headline move is extracting AYN's vendor DTB from
the Android partitions on the device itself (dual boot = ground truth for the real
jack-detect wiring). Session history below:

HEADPHONE JACK 2026-08-12 (deep session; kernel 7.1.3-15 = first REAL build with the fix):
Diagnosis chain: (1) UCM had a DUPLICATE Headphones SectionDevice shadowing the correct
PCM (fixed, bsp-sm8750-11; Headphones sink now EXISTS in WirePlumber — first time). (2)
MBHC mech detect armed (0x3014=0xBD) but ZERO codec interrupts ever — jack lines dead.
(3) The wcd939x USBSS mux (i2c 2-000e, PAGED 8-bit regmap: selector reg 0x00 = page,
window 0x100 — 16-bit i2ctransfer frames are gibberish, reads return zeros that LOOK
like a dead chip; reset-gpio low is CORRECT/deasserted, red herring) sits in USB mode
(0x419 mode=5), disconnecting the jack from the codec. Manual HSJ programming (paged
pokes, sequence from wcd939x_usbss_set_hsj) routed the lines but detect STILL silent
and the Headphones PCM OPEN HANGS -> deeper kernel gaps. ROOT CAUSE OF THE GAPS:
ROCKNIX solved the whole jack UPSTREAM after our founding sync (Pocket Fit Elite
bring-up): 0059/0060/0063/0064/0072/0073/0074 audio series + 0509 altmode-defer.
Kernel-13 = that series synced into 20-sm8750; our batocera 0605 REMOVED (superseded
by their 0063 route-usbss-on-integrated-jack-insert). TEST AFTER DEPLOY: plug ->
codec irq fires -> Headphone Jack control flips on -> WirePlumber auto-switches ->
sound; also verify speakers + suspend soak (audio patches are suspend-inert but soak
anyway). Wiretap lesson: watch /proc/interrupts "WCD939x" parent + amixer CARD
"Headphone Jack" control. pkill -f self-match bug struck AGAIN (third time) — bare
pkill -x ONLY over ssh.

TOMORROW'S DOCKET (in order):
0. RUMBLE IN-GAME (Cyberpunk) — the week's unclaimed prize; test FIRST before anything
   can crash. Hardware rumble is proven (remote FF pulses felt); only Steam->game routing
   unverified.
1. OVERLAY JAM — 100% reproducer: Steam menu while in Cyberpunk -> doubled/oversized
   menus + dead input. Theory: input-path jam + steamwebhelper death. Suspend-cycle
   un-jams it (corroborates). Rescue: ssh + pkill GameThread. Hunt with the wiretap +
   live gamescopectl during a jam.
2. SUSPEND-DURING-GAME controller loss — sleep hooks restart InputPlumber, running games
   never re-acquire the recreated pad ("controller disconnected"). FIX DIRECTION: move
   the IP target off deck/USB-IP (vhci suspend veto is WHY we stop IP) to a uhid target
   (ds5 — ROCKNIX's approach) so IP survives suspend. SteamOS-parity sleep is the prize.
3. Artists: reply to Tall-Bass (boot video + palette answer + comms channel; front-runner,
   ~$272, same TZ); nudge Finamore for pixel-native samples ($300-500, elite timing).
4. ~~Battery telemetry logger~~ DONE 08-08 + eco/balanced/performance power profiles
   SHIPPED (CLI pocknix-power-mode + QAM Power-tab selector; eco measured: same load
   10C cooler, fan OFF, charges faster). Fan hotspot fix deployed. Next: per-profile
   game benchmarks (Ashes built-in bench), sleep-drain %/hr from overnight CSV gaps.
5. ~~7.1.3-9 ceremony~~ DONE 08-09: SUSPEND SAGA CLOSED (0513+0508 validated, 3/3 soak,
   rsinput loaded through sleep, buttons fine post-resume) + STICK LEDS GLOW
   (pocknix-stick-leds, 24ch, Hodor-orange debut). Headphone jack now testable (0605).
   Remaining staged: GPU pair 0050/0051 (own soak). Polish: LEDs-off-in-sleep hook;
   ship autoconnect-retries=0 in wifi preseed (NM retry-exhaustion sulk, fixed live).
6. batocera.pocket PATCH KIT staged + primed (kernel/sm8750/patches-staged/batocera-pocket/
   — READ ITS README): 0513 = suspend-saga full-closure candidate (restores 0508 safely),
   HTR3212 stick RGB (driver + DTS mapped), headset-USBSS, a8xx GPU stability pair, amp
   race fix. Reference fan/charge-limit/wifi scripts in docs/reference/batocera-pocket/.
7. Public-release track: README + install docs -> Cliff's two dogfood installs; Steam
   seed decision (download-at-first-boot needs a network-install fallback in the
   launcher — test hard); per-install password generation; strip Wi-Fi preseed.

## STATUS 2026-08-02: v0.2 BOOTS CLEAN — Steam, controls, Wi-Fi, zero manual surgery.

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
6. **InputPlumber / THE BUTTON SAGA (final, wiretap-proven 2026-08-08)**: composite configs
   gate on the dt model string (`AYN Odin 3`). The Odin 3 MCU emits pure POSITION codes
   (raw-capture proven); AYN labels are Nintendo-style; and the CORRECT capability map is
   ASYMMETRIC — A/B pair crossed, X/Y pair straight — because Linux's legacy evdev aliases
   are themselves asymmetric (BTN_SOUTH==BTN_A/BTN_EAST==BTN_B are position-named, but
   BTN_NORTH==BTN_X/BTN_WEST==BTN_Y are letter-crossed) and InputPlumber's deck target
   follows the aliases. Both "consistent-looking" maps are half-broken; bsp 0.2.0-6 is
   the truth. VERIFY INPUT BUGS AT THE LAST BOUNDARY: evdev-wiretap Steam's virtual x360
   pad during labelled presses (script pattern in session notes) — intermediate layers
   (test screens, configs) all lie in different ways. Steam's test screen draws a DECK
   diagram: positions always look crossed on Nintendo-labelled hardware; judge by
   LETTERS + function. Per-game Steam Input configs AND their cloud copies are where old
   compensating remaps hide (Cyberpunk carried both a cloud remap and a mangled autosave).
   NEVER restart inputplumber / deploy input configs while a game runs (mid-game
   controller yank = crash or disconnect).
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
FIRST INTERNAL BOOT (2026-08-05): SUCCESS — boots fast, Balatro/Elden Ring/Expedition 33
installed, downloads healthy. Lepton/FEX hunt result: BOTH visible in the client
(Library search -> Tools filter) but install falls back to "stream from BONESAW" — their
appinfo carries release-state **ownersonly** = license-gated, NOT hardware-gated. No
store page => no way to self-grant the free license yet. Valve's pattern (Proton,
runtimes) auto-grants tool licenses when a game requires them — expect the gate to open
at/near Frame launch or when Android-depot games ship. Lepton GPU caveat (Discord intel 2026-08-05): Waydroid/Lepton has NO GPU accel on
Adreno 830 — the container's Android-side mesa predates turnip a8xx (Frame is an
A750 = a7xx, so Valve won't fix it for us). Our HOST turnip 26.1.5 drives the A830
fine, so the eventual play is grafting our mesa build into the container's GPU libs.
Lepton appid = 3029110
(steamdb.info/app/3029110). FEX appid: TODO extract from appinfo.vdf (v29 header parse —
script pattern in session notes) next time the device is awake. Device now at
192.168.1.19 (internal boot lease).

## RUMBLE WORKS 2026-08-06 — kernel 7.1.3-6 DEPLOYED, vibration physically confirmed

Deployed via pacman -U; the FIXED bootimg hook rebuilt /flash/KERNEL on-device (first
time — debt paid). Boot clean; qcom-hv-haptics probed the PMIC (HAP_CFG 0x501), rsinput
linked to it (FF bridge live), THREE FF devices exist (raw haptics, gamepad, Steam's
virtual pad). Remote FF pulses at max strength: CLIFF FELT THEM — both the bridge path
and the raw path. REMAINING: in-game rumble test (Steam->virtual pad->InputPlumber->
bridge), suspend cycles under the PCIe-GDSC fix, deadzone feel.
BONUS RECON same evening: battery charge-control sysfs is LIVE on our kernel
(charge_control_end/start_threshold, defaults 80/70, writes honored; USB
input_current_limit exists) — Armada lacks UI for this too => "Battery care" panel in
the Pocknix Control Decky plugin = high-visibility differentiator, filed. Sleep-drain
positioning: we do real deep suspend; measure %/hr (telemetry logger) before claiming
numbers; note the PCIe fix may cost some sleep drain — measure the tradeoff.

## RUMBLE KERNEL notes (superseded — kept for the deploy checklist)

Kernel build env now on fusor (cross aarch64; base-devel + aarch64-linux-gnu-gcc; make
kernel works). linux-pocknix-sm8750 **7.1.3-6** in localrepo carries: ArmadaOS's ported
haptics set (kernel/sm8750/patches/40-holodor/ — see its README for credits/contents),
DTS hv-haptics+SDAM+rumble/deadzone props (DTB verified), CONFIG_INPUT_QCOM_HV_HAPTICS=m,
AND the fixed fw-initramfs pocknix-build-bootimg hook (debt closed). DEPLOY (with Cliff):
scp pkg -> pacman -U on device (hook rebuilds /flash/KERNEL) -> reboot -> TEST: rumble in
a game, stick deadzones, suspend cycles (PCIe GDSC fix may kill the wedge), controls
after resume (kernel MCU reinit now backs the sleep-post retry). Keep the old KERNEL.bak
on /flash as rollback; SD rescue card also boots.

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
- **In-game Steam overlay broken — REFRAMED 08-07 (live forensics during a stuck state)**:
  not a gamescope/rotation bug. Evidence: zombie steamwebhelper present in the wreckage
  (both occurrences), Steam suddenly discovering the RAW gpio-keys-paddles device it
  should never see (doubled input paths = the "two competing menus"), game itself healthy
  underneath. Working theory: a mystery SECOND InputPlumber instance ran at boot+44s and
  its shutdown un-hid a source device the main instance was managing -> Steam grabbed it;
  overlay chaos + webhelper death follow. TODO: find what spawns the second IP instance
  (pid 7059 that boot); verify paddle visibility to Steam in a healthy session; consider
  re-asserting udev hides post-boot. RESCUE PROTOCOL (no more 15s power holds): SSH in,
  pkill the game process -> Steam UI recovers.
- **Cyberpunk per-game layout scar** (08-07): the game played during the map-troubleshoot
  era carries a swapped X/Y layout in its per-game Steam Input config. Fix = apply the
  official default "Gamepad" template from the game's controller page (Library, NOT the
  broken in-game overlay). System layer is raw-capture-proven correct; per-game configs
  are the last place old chaos hides. NEVER edit binding VDFs while Steam runs.
- **Suspend no-wake wedge: SOLVED 2026-08-08** (pending field confirmation). The boot
  ledger showed 100% of boots wedged since the rumble kernel; two controlled rtcwake
  module-bisection rounds convicted rsinput — specifically patch 0508 (MCU reinit on
  resume, ironically imported to FIX resume). Kernel 7.1.3-7 ships without it (parked in
  patches-disabled/ for a 7.1.5 iteration; armada runs it fine on their base — find the
  supporting delta before re-adopting). The rsinput sleep-guard hooks (bsp-common
  0.1.0-4) are DISABLED on-device for naked kernel validation — restore the two files
  from the package if the wedge somehow returns. NOTE: the guard's side effect (module
  yank under a running game) crashes some games (Cyberpunk) — don't ship it enabled
  long-term.
- **Cyberpunk X/Y mystery: SOLVED** — Cliff had remapped X<->Y in Steam Input during the
  wrong-map era; after the map fix underneath, his remap became the bug (the autosave
  also ended up mangled: BOTH X and Y bound to xinput Y). Quarantined
  (controller_steamos_handheld.vdf.mangled.bak); game falls back to default template.
  LESSON: layered fixes fight — when a layer gets fixed, audit the compensations made
  above it (Steam per-game configs are the last hiding place).
- **X/Y FIX STAGED, UNTESTED**: bsp-sm8750 0.2.0-4 (c2a554e) maps X/Y straight-through
  (Cyberpunk field test showed prompts matching the OPPOSITE labelled button; the
  sm8550-era driver inversion doesn't exist on the Odin 3 MCU — same lesson as A/B).
  Install on device + verify in Steam's controller test before calling it done.
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

## Community intel (AYN Odin 3 Linux Discord, via Cliff 2026-08-04)

Gaps the community sees in Odin 3 Linux generally — our position on each:
- **Rumble**: dead everywhere; armada issue #134 has the full diagnosis — kernel has
  qcom_hv_haptics + an rsinput FF bridge (newer than our 7.1.3 snapshot), but the DTS
  lacks the PMIH0108 hv-haptics node. Our tree confirmed: pmih0108.dtsi included, NO
  haptics node, driver not in config. FIX PATH = next kernel iteration (bump toward
  7.1.5, port/enable driver+node+bridge, cross-compile env on fusor) — which ALSO ships
  the fixed pocknix-build-bootimg hook. Armada CONFIRMED working (2026-08-05: first crashed, maintainer fixed it) — find both
  the enable commit AND the crash fix in their kernel tree when porting.
- **Sleep/wake**: our resume race is hardened (bsp-common-2); one idle-suspend wedge
  unexplained. Community sees perf issues too — Qualcomm resume latency is partly
  inherent (remoteproc restarts).
- **Battery**: sudden 30-40% drops reported; likely BOTH real (cpuidle state disabled
  for GMU = idle drain) AND gauge artifacts (pmic_glink battmgr; we log 'health' errors).
  TODO: battery telemetry logger to separate gauge jumps from true drain.
- **Lossless Scaling (lsfg-vk)**: hard to set up on armada per community; niche, backlog.
- **Thumbstick RGB**: the stick LED rings don't work on armada either. Likely driven by
  the RSInput MCU (Android controls them via AYN's app) — investigate whether the MCU
  protocol exposes LED commands (InputPlumber has LED target support if so).

## Future: sm8550 family expansion (RP6 / Odin 2 line / 8 Gen 2 devices)

After Odin 3 reaches public quality: the pocknix harness's HOME TURF is sm8550 — our
repo still carries its maintained devices/sm8550 + kernel/sm8550 trees (we inherited our
board configs FROM them), Adreno 740 turnip is MORE mature than our A830, and Holodor's
inventions (Holo graft, seed bake, fw-initramfs, clock seed, sleep hooks, battery-care)
are SoC-agnostic. Costs: physical hardware per board for QA (the last 10% is always
board quirks) + multiplied release testing. ~10x the addressable audience.

## Credits / license posture

GPL-2.0-or-later fork of pocknix-os (pending their license), crediting ROCKNIX, Armada,
Valve/Collabora (Holo Core), FEX, and Mesa/Turnip.
