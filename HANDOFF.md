# Holodor — handoff to fusor (2026-08-02)

**Holodor is a SteamOS-faithful Arch Linux for the AYN Odin 3** — Valve's Holo Core aarch64
userland + ROCKNIX SM8750 kernel, built on a fork of the pocknix-os harness.
Repo: `github.com/transentient/holodor` (PRIVATE, branch `holodor-main`).

## CURRENT STATE 2026-08-14 LATE (Fable continuation) — READ THIS FIRST (supersedes all below)

### 🎯 THE ANDROID BOOTLOOP HAD TWO LAYERS. Layer 1 SOLVED + permanently fixed.

**Layer 1 — self-inflicted UNBOOTABLE-SLOT brick (SOLVED, durable fix shipped).**
The ROCKNIX ABL boots Holodor *through Android's A/B slot machinery*
(FindBootableSlot/LoadImageAndAuth). The A/B retry counter lives in the GPT attribute
flags of the **boot_<slot>** partition (Qualcomm/msm layout: byte 6 = priority[0-1],
active[2], retry[3-5], successful[6], unbootable[7]; sgdisk attr **bit 54** == successful).
`boot_b` was the ONLY slot-b partition never marked "successful" (0x3F while every other
`*_b` was 0x7F), so its retry ticked down on **every** boot — our own Linux boots AND each
failed Android attempt — 7→0, then the ABL flipped slot b **UNBOOTABLE** and refused BOTH
OSes. That's the verbose-log smoking gun: KERNEL loads+verifies fine, then
`LoadImageAndAuth ... Slot b is unbootable, trying alternate slot → FindBootableSlot() Load
Error`. This is what broke Linux mid-session (it had booted fine all day; the counter just
hit zero). **Recovered live: `fastboot set_active b`** (resets retry, clears unbootable).
**Permanent fix shipped:** `pocknix-slot-successful` boot service marks the active slot's
boot partition successful each boot, idempotent, on-device tools only (sgdisk). bsp-common
pkgrel 13, commit **f5fa8b2**, enabled in build-sd-image; validated on-device (no-op when
already good, re-sets when cleared). boot_b is now 0x7F. **This can never silently
re-brick.** (Retroactively: the historic "retry 6" note + every "returns to menu / bounce"
was slot depletion compounding.)

**Layer 2 — the ORIGINAL Android abort (STILL OPEN, blocked on Cliff).** Even with a
healthy slot, ROCKNIX-ABL "Boot mode Android" (USB **unplugged**) aborts *cleanly back to
the ABL menu* — NOT a kernel loop (that logo→vibrate→black loop was the USB-attached /
stock-ABL fastboot path, a red herring). The Rescue eng agent (a85c161e) traced this to the
ABL's boot-decision/LoadImageAndAuth stage, keyed off ROCKNIX **devinfo TLVs** (BootMode @
devinfo 0xb4e, BootSourceMode @ 0xa92, ModelSelection="AYN Odin 3"; unlock flags at
0x0d–0x0f are physically isolated — TLV edits can't relock). Agent's earlier "ABL chose
EFI-boot" headline was WITHDRAWN (drawn from non-representative stock-fastboot logs).
**Can't test autonomously — booting Android drops ssh and needs Cliff's hands at the ABL
menu to recover.** NEXT (Cliff's hands): now that slot b is healthy, **just retry "Boot
mode Android"** — it may work (the bounce may have been the unbootable slot all along). If
it STILL bounces: agent's **T3** = flash stock ABL both slots, USB **disconnected**, force
an Android boot, then dump logfs and grep for **"Booting Into Mission Mode"** (present ⇒
Android path reached, read the next line for the real abort; absent ⇒ decision-stage skip).
AYN email drafted at `docs/android-recovery-ayn-email-draft.md`.

### CYBERPUNK fps — max mode shipped, bench plan ready
- **New `pocknix-power-mode max`** (commit f68b366, deployed): GPU devfreq min=max **pinned
  at 1100 MHz** + CPU governor `performance`. Measured: `balanced` was capping the GPU at
  **900 MHz** (of 1100) — and ALL prior AAA numbers were taken in balanced, so they undersell
  the hardware. Thermals wide open (GPU 39–40 °C idle).
- **Honest ceiling reminder:** prior investigation found Cyberpunk is **present-path /
  wait-bound**, not GPU-bound (GPU ~52% at the ceiling). So expect `max` to give an
  incremental native bump (mid-20s/low-30s realistic), and lean on **lsfg-vk frame-gen**
  (already proven) for perceived fps. @ice's 41 is likely frame-gen-assisted.
- **Ready-to-run bench matrix + one-liners: `docs/cyberpunk-bench-plan.md`.** Needs Cliff +
  display (can't bench headless). Launch options already clean; FEX global = default (TSO on).

### Device state RIGHT NOW (safe)
- Boots Holodor by default, up at 192.168.1.26, slot b healthy+successful (0x7F), kernel-18,
  audio up. **Sleep-guard active** (`fable-inhibit.service`, ~4h idle-suspend block — it may
  expire; if the box is unreachable later it just idle-suspended, wake with a power tap).
- E-MBR change from earlier is LEFT in place (sda protective MBR now factory-style 0xFFFF..;
  harmless, didn't fix Android, one fewer variable). devinfo/GPT backups on device at
  /root/{devinfo-backup-20260815.bin,sde-gpt-backup-20260815.bin,sda-sector0-backup-*.bin}
  and repo odin3-abl-backup/.
- Commits this session (LOCAL, not pushed — fusor Bash had no outbound https; push when able):
  f68b366 (power-mode max), f5fa8b2 (slot-successful keeper). Earlier f7eab2f pushed.

## CURRENT STATE 2026-08-14 EVENING — (superseded by the block above for Android/slot state)

Written at session pause ~16:30 by Fable 5. Project memory (odin3-holocore-project.md,
2026-08-14 entries) has the play-by-play. The morning block below is still accurate for
Cyberpunk/lsfg/jack-audio state; THIS block is the Android-recovery + audio delta.

### Device state RIGHT NOW (safe, verified)
- Boots Holodor by default: active slot b, abl_b = **rocknix-abl v1.1.7** (NEW — upgraded
  from v1.1.5), abl_a = **STOCK AYN abl** (from BONESAW backup), root /dev/sda19, kernel-18,
  audio up. ROCKNIX ABL settings live in devinfo TLVs: BootMode=Linux, Model=AYN Odin 3.
- **v1.1.7 ABL quirks**: new devinfo key = one-time "DEVICE MODEL NOT SET" re-setup after
  upgrade; model menu caps at ~10 entries (overflow bug — shows alphabetical TAIL of the DTB
  catalog, so "AYN Odin 3" is unreachable with our 100+-dtb KERNEL payload). Worked around by
  trimming the rescue SD's KERNEL to a single DTB (original backed up at
  odin3-abl-backup/KERNEL-rescue-sd-backup-20260814). UPSTREAM REPORT DUE + we should ship a
  trimmed DTB payload permanently. VOL–+power only enters the menu from POWER-OFF.
- **Slot A = complete factory Dec-2025 Android** (EDL package chain incl. stock abl_a) — flashed
  during today's experiments, verified byte-perfect. Slot switching works via fastboot
  set_active (fastboot = stock ABL's menu; ROCKNIX abl lacks `oem`/set_active testing so far).

### ANDROID: still broken — but massively narrowed (the day's main work)
Every cheap theory is now EXONERATED BY TEST: images (all slot-B AND factory Dec-2025 slot-A
chains verify perfectly with avbtool vs AYN's signed vbmeta), slots (fresh slot A, attrs
healthy, retry 6), ABL builds (ROCKNIX v1.1.5, v1.1.7, AND stock all fail), recovery mode
(bounces identically), rollback (indices 0=0), devinfo core (unlocked=1 read fine), misc
(BCB zeroed, virtual-A/B msg healthy), GPT (parses clean both disks), sda18 FAT (factory
modem_b is also basic-data vfat → the ABL's "No \EFI\BOOT\BOOTAA64.EFI" search is an
old fallback, not new behavior). **THE DECISIVE DATAPOINT: `fastboot boot boot.img` (RAM
boot, bypasses ALL disk/partition state) ALSO fails to start the kernel** — "Booting OKAY"
then bounce back to menu, no display output. Combined with UEFI logs showing the stock ABL
never prints "Booting Into Mission Mode": the failure is in the BOOT-TIME ENVIRONMENT the
ABL builds for Android (DTB/DTBO selection vs smem platform IDs — note UEFI log says
"Platform: HDK" while AYN's DT is "Sun QRD" — pvmfw/vm-bootsys load, or ddr/memory map),
NOT in any partition content or A/B state. Device is UNLOCKED (+critical), Secure Boot OFF.
- Assets ready: EDL pkg extracted+verified (fusor scratchpad edl-pkg/ + repo
  odin3-firmware-20251206/), all boot-chain images staged on device /root/edl-stage/,
  stock ABL backups sha-verified (repo odin3-abl-backup/), avbtool.py in scratchpad,
  android-tools on fusor, fastboot flow proven end-to-end.
- NEXT IDEAS (untried): compare failing env vs the one config that DOES boot (Linux via
  ROCKNIX ABL — what does it do differently? no dtbo, own DTB, no pvmfw?); dump smem
  platform ID vs dtbo board-ids (vendor-archaeology tools can decompile dtbo entries);
  raise ABL log verbosity (uefivarstore vars?); EDL-load ONLY xbl_config/aop_config?…;
  ask AYN (lucia@ayn.hk) what "Platform: HDK" should read on retail units; ask Discord
  whether ANY Odin 3 dual-boots Android via rocknix-abl (if yes → get their UEFI log).
- **Jack-detect test remains blocked** on Android booting. Shipping mode = manual switching
  regardless (unchanged).

### AUDIO: pre-RC panic DOWNGRADED (two real-but-small bugs)
- The day's "no sound" reports were TWO things: (1) morning boot = SoundWire codec enum
  timeout → card never probes → auto_null only (dmesg: "swrm_wait_for_frame_gen_enabled:
  link status not disconnected" + "failed to instantiate card -110"; RARE — 1 of ~6 boots
  today; reboot fixes; consider probe-retry patch). (2) All other silent boots = WirePlumber
  restoring Speaker sink at **volume 0.00** (persisted state; probably zeroed via Steam
  while audio was dead during the Android mess). Fixed by setting 0.70 — now persisted, so
  future boots are audible. bsp-13 routing fix HOLDS; not a routing regression.
- Watch item: one `qcom-apm CMD timeout [1001021]` during boot (DSP slow to answer) — benign
  this time, but same disease family as the codec race.

### Cyberpunk / fps (agent review done — full report in 2026-08-14 session transcript)
- **Odin 3 Ultra = SAME SoC/GPU/clocks/RAM-speed as our Max** (capacity-only SKU). The 41-vs-21.5
  native gap is ~0% silicon. Cliff's "25% more fps" memory is wrong (~90% more).
- Ranked squeeze list: (1) pin GPU devfreq min=max in performance mode (Armada does this —
  our pocknix-power-mode only sets max) + cpu governor performance; (2) fan mode default is
  QUIET — bench under performance/max fan; (3) REMOVE PROTON_LOG/VKD3D_DEBUG launch options;
  (4) scx_lavd/schedutil A/B; (5) DDR bandwidth votes (7.1.3 vs 7.1.5 GMU); (6) mesa-next
  26.3.0-devel A/B (already packaged). Realistic target mid-30s native; turnip A8xx is young
  (Mesa 26.0 first Gen8) → future mesa likely +10-30% more.
- Questions for @ice drafted in the session (bench scene/settings, his power+fan profile,
  his `cat /sys/class/devfreq/*.gpu/cur_freq` during play, panel refresh).

### WHAT WE WERE WRONG ABOUT TODAY (2026-08-14) — read every line before theorizing

- **"ROCKNIX ABL's Android path is broken" — WRONG as the root cause.** Stock AYN ABL
  fails identically (START bounces, Recovery bounces). Do NOT spend time on ABL bug
  reports for the bootloop itself (the 10-entry menu cap IS still a real, separate bug).
- **"The RAW userdata / metadata format caused the loop" — WRONG.** AYN's own fstab
  (extracted from vendor_boot ramdisk) says metadata is SUPPOSED to be f2fs, and both
  metadata and userdata are `formattable` — Android auto-formats them. The 2026-08-13
  f2fs repairs were correct but irrelevant to the loop.
- **"Slot retry counters exhausted / slot marked unbootable" — WRONG.** fastboot getvar:
  slot b retry 6, successful, not unbootable. Do NOT chase slot-attr repair.
- **"sda18's FAT partition seduces the ABL into EFI boot" — WRONG.** sda18 is
  Microsoft-basic-data (not ESP), and factory modem_b is ALSO basic-data vfat, so the
  ABL's FAT scan always had targets. The "No \EFI\BOOT\BOOTAA64.EFI" search is an old
  fallback that only LOOKS new.
- **"Upgrade to abl v1.1.7 might fix Android" — DIDN'T.** Its delta is USB-boot/menu
  work. (The upgrade stayed anyway — better UI, Cliff loves it.)
- **"bsp-13 boot-silence fix regressed / new audio race is RC-blocking" — MOSTLY WRONG.**
  All but one of 2026-08-14's silent boots were WirePlumber restoring Speaker at volume
  0.00 (persisted state, probably zeroed via Steam while audio was dead on 08-13 night).
  Now persisted at 0.70. Only the SoundWire codec-enum timeout (1 boot of ~6) is a real
  race. Do NOT tear apart bsp-13.
- **Cliff's "@ice gets ~25% more fps" — WRONG NUMBER.** It's ~90% more (41 vs 21.5
  native). And "maybe I should buy an Ultra for the fps" — the Ultra is the SAME
  SoC/clocks/RAM-speed (capacity-only SKU); silicon explains ~0% of the gap.

### TRAPS (2026-08-14 additions)

- **VOL–+power from a RUNNING system = plain reboot.** The ABL menu combo only works
  from power-off (or by holding VOL– through a reboot).
- **abl v1.1.7's model list reads the boot source's KERNEL payload and caps at ~10
  entries** — with our full-DTB-zoo KERNEL, "AYN Odin 3" is unreachable. The rescue SD's
  KERNEL is now trimmed to one DTB as the workaround (its KERNEL.md5 sidecar updated;
  original at odin3-abl-backup/KERNEL-rescue-sd-backup-20260814). If model setup is ever
  needed again: boot source SD → set model → boot source Internal.
- **Never corrupt the devinfo header** (ANDROID-BOOT! magic + unlock bytes at the front).
  If the ABL regenerates devinfo defaults, the device could re-LOCK → fastboot flashing
  restricted + AVB enforcement on our modified system = much worse hole. Surgical tail
  edits only, backup first (forensics copy in fusor scratchpad + this session's dumps).
- **EDL/QFIL remains ABSOLUTE last resort** — rawprogram repartitions sda = destroys
  Holodor. Everything needed so far has been achievable via fastboot + dd from Linux.
- The Odin **idle-suspends during long sessions** — ssh dies mid-work; wake = power tap
  (Cliff). Not a crash.
- `fastboot` needs sudo on fusor (no udev rule for QC VID). `fastboot oem help` is
  unsupported on this ABL.

### NEXT (ordered)

1. **Discord recon (free, decisive):** ask the Odin 3 Linux Discord whether ANYONE
   dual-boots stock Android via rocknix-abl on an Odin 3 (not Odin 2). If yes → get
   their abl version + whether they did the internal install. If no one → the bootloop
   may be universal on Odin 3 and upstream/AYN escalation is warranted. Also post the
   @ice benchmark questions (in HANDOFF Cyberpunk section / session transcript).
2. **DTB/platform-ID theory:** decompile the dtbo entries' board/msm-ids
   (tools/vendor-archaeology has the toolchain; dtbo_b image already on fusor at
   scratchpad slotb/dtbo.img) and compare against what XBL reports ("Platform: HDK",
   Subtype 1, ChipVer 2.0 per UEFI log). If AYN's entries say QRD and the ABL matches
   platform-type, that's the bounce. Counter-evidence to explain: it worked before
   2026-07-26 with the same images — so if this theory holds, something must have
   changed what smem/socinfo reports (or the theory is wrong).
3. **ABL verbosity hunt:** find how to raise QC ABL log level (uefivarstore variable?
   BDS menu? `fastboot oem` variants are unsupported) so the silent pre-"Mission Mode"
   failure names itself in UefiLog. The logfs read recipe is proven (mount FAT12 loop,
   UefiLog0-4, 64K space-padded, level-filtered).
4. **Email AYN (lucia@ayn.hk, Cliff's contact from July):** describe the symptom
   (unlocked device, verified-intact images, stock ABL bounces to fastboot pre-splash,
   RAM boot also fails), ask what state the ABL checks before Mission Mode and what
   "Platform: HDK" should read on retail. They shared the EDL package before; they may
   just answer.
5. **Audio polish (pre-RC):** add SoundWire codec probe-retry (or systemd retry of the
   card bring-up) for the 1-in-N enum race; consider a WirePlumber floor so Speaker
   never restores at 0.00; watch for more `qcom-apm CMD timeout` lines.
6. **Cyberpunk squeeze session (Cliff + agent):** GPU min-freq pin test first (5 min),
   fan=performance, strip PROTON_LOG from launch options, rerun the 720p/Low bench
   ladder. Then the release-image rebuild + client-channel decision (unchanged from
   morning block item 1).
7. Housekeeping: delete /root/edl-stage (~460MB) and /root/*.img abl staging files on
   the device once Android work concludes; report the v1.1.7 model-menu cap upstream;
   ship trimmed DTB payload in our KERNEL (saves ~40MB, fixes the menu).

### Open questions

- Why does the ABL abort Android boot pre-"Mission Mode" in every configuration while
  Linux (via ROCKNIX ABL, no dtbo, own DTB, no pvmfw path) boots fine? Top theories:
  DTB/DTBO platform matching, pvmfw/vm-bootsys env, something smem/socinfo-side.
- Did stock Android dual-boot EVER work post-internal-install on ANY Odin 3, or did the
  2026-08-04 install break an assumption nobody has tested? (Discord question #1.)
- Which slot does XBL use for uefi/tz/hyp after set_active flips — and did today's slot-A
  experiment actually run slot-A's uefi_a chain (UEFI logs looked identical)? Probably
  irrelevant post-restore (active=b), but note it.
- misc blobs at 0x8080 (01 0c 11 b5 6a) and 0x80c0 (01 'roms') — whose are they? Benign?

### Untracked repo debris (deliberate, gitignored — do not commit)
odin3-abl-backup/ (stock ABL backups + SD-KERNEL backup), odin3-firmware-20251206/ (1.9GB
EDL zip). Both now in .gitignore.

## CURRENT STATE 2026-08-14 MORNING (still valid except where superseded above)

Written at session close 2026-08-14 ~00:45 by Fable 5, after a ~16h session. The
project memory (odin3-holocore-project.md) carries the same story in more detail —
its 2026-08-13/14 entries are required reading before touching audio, FEX, or Android.

### Where things are

- **Device**: internal-UFS daily driver, kernel 7.1.3-18, bsp-sm8750 0.2.0-13,
  pocknix-steam 0.1.0-38, pocknix-decky 0.1.0-13, lsfg-vk 2.0.0dev-1, IP 0.77.2.
  Steam client = Valve's STABLE arm64 channel (steamdeck_stable, 1785799196) — NEW:
  this channel now exists; device launchers (/usr/bin/steam, /usr/bin/pocknix-steam)
  were sed-patched on-device from publicbeta→stable. **REPO STILL PINS publicbeta**
  (packages/pocknix-steam/{steam,pocknix-steam}) — DECISION PENDING which to ship.
- **Headphone jack: WORKS** (stereo, both channels, manual output switching = the
  shipping mode). MBHC auto-detect still dead (zero irqs ever); the decisive
  Android-comparison test is BLOCKED (see Android below). Right-ear idle hiss at
  no-signal = polish item (codec noise floor, audible because sinks never suspend).
- **Boot audio: FIXED for real** (bsp-13, commit 5cf8012) — q6apm quirk: writing 0
  to any FE route on a backend RESETS that backend's mixer and drops its other FE
  routes; the verb's MM2-clear must run FIRST. Cold-boot verified.
- **Cyberpunk: stable.** 720p/Low benchmark: 21.5 native, 25.6 with FSR3.0
  upscaling, **34.28 with FSR3.1 upscale + the game's OWN FSR3 frame generation**
  (which works fine now — see WRONG section). Virgin install (85G), Steam Cloud OFF
  for the app, saves backed up at /root/cyberpunk-saves-backup-20260813.tar.gz.
- **Frame insertion (lsfg-vk): proven end-to-end** on hardware (layer + host turnip
  mapped inside a running game; CLI benchmark 656 generated fps at 720p = ~1.5ms/frame
  on A830). Shipped: packages/lsfg-vk (upstream develop @8b0da266, ROCKNIX's pin),
  QAM "Frame Insertion" toggle + multiplier, six per-flag FEX toggles (Armada
  Control parity), wrapper env plumbing. fex-emu ThunksDB now overlays Arch guest
  paths (f16e268) so the Vulkan host-thunk can actually engage (localrepo pkg rebuilt;
  device ThunksDB.json hand-patched to match, backup /root/ThunksDB.json.bak).
- **Android dual-boot: BROKEN** (bootloop: AYN logo → vibrate → black → repeat, dies
  pre-init). New project item. Possibly broken since the July 26 ABL flash — tonight
  was plausibly the FIRST Android boot attempt since. See NEXT.
- Suspend/rumble/buttons/LEDs/power-stack: all still green from prior sessions;
  kernel-18 additionally passed 3/3 PLUGGED-IN rtcwake soaks + clean shutdowns
  (the 0611 typec crash guard works; battery gauge stays sane).

### What we did 2026-08-13 → 08-14 (compressed; memory has the play-by-play)

Deployed+validated kernel-18 (0610 v4 vendor HSJ + 0611 guard; NOTE the v4 symbol is
inlined — verify via strings on wcd939x-usbss.o, NOT System.map). Root-caused and
shipped the boot-silence fix (bsp-13). Discovered the FEX preset pipeline already
existed end-to-end; added per-flag toggles + Frame Insertion UI (decky-13, steam-38).
Built lsfg-vk from source (never ship the decky plugin's provenance-lost ARM blob);
proved the whole chain live in Hades. Jack listen test: left channel was a PHYSICAL
plug-seating issue — reseat+twist fixed; kernel-18 routing was correct all along.
Solved the two-day Cyberpunk crash saga (see WRONG). Cliff's benchmark ladder vs the
Discord rival's numbers. Android boot rescue attempt: fixed one real installer bug
(userdata left RAW — formatted f2fs+metadata via ALARM f2fs-tools binary) but the
loop is earlier in the chain; parked with diagnosis banked.

### WHAT WE WERE WRONG ABOUT — read every line; each cost hours

- **THE BIG ONE: every Cyberpunk crash of 08-12/13 was the global FEX profile set to
  "fast" (TSOEnabled=0)** in /etc/pocknix/game-tweaks.json. TSO-off on 8-core Oryon
  corrupts heavily-threaded x86 games: wandering SEGV/SIGBUS/int3 at 15-150s, one
  repeating address (0x140243742) plus scatter. Light titles (Balatro/VS/Hades)
  mostly survive → faked "game-specific" evidence. The wrapper injects this into
  EVERY launch, so it survived: FSR3-settings revert, vkd3d cache purge, engine
  GamePipelineLibrary.cache purge, mesa_shader_cache purge, full scorched-earth
  reinstall (Steam uninstall does NOT touch OUR tweaks file), kernel-17 rollback,
  AND the Steam-client rollback. ALL of those theories were WRONG in sequence. When
  an FEX game misbehaves: **check game-tweaks.json FIRST.** "Fast" preset is now
  labeled unstable (300c2be); consider a stronger guard.
- **Cliff's original "frame insertion" crash (08-12 evening) was the GAME'S OWN FSR3
  Frame Generation setting** — not lsfg (which didn't exist here yet), and probably
  not even FSR3's fault (TSO was already poisoning it — FSR3 FG works fine now).
  Lesson applied twice today: ask what the user LITERALLY did before theorizing.
- **"vkd3d crashes on the Vulkan host-thunk" — CONVICTION VOIDED.** The Cyberpunk
  thunk test ran while TSO-off was active. The repo wrapper (b95cb53) switched lsfg
  to a guest-x86-layer route based on that conviction — the change is REPO-ONLY,
  UNVALIDATED, and NOT in the deployed steam-38 (device wrapper still uses the
  thunk route, which is the config that actually worked in Hades). RE-TEST the thunk
  route with TSO on before accepting b95cb53's guest-mode default; the x86_64 layer
  build exists at /home/deck/lsfg-x86/ if guest mode is still wanted.
- **"Hades 120fps = insertion working" — AMBIGUOUS, do not cite.** Hades may run 120
  native on the 120Hz panel. Overlay/benchmark fps counters read BASE rendered fps;
  lsfg's doubling is invisible to them (Cyberpunk bench: 25.58 with insertion ≈
  25.62 without — that is the counter's blindness, not proof of failure). Presented-
  rate verification (gamescope side) still TODO.
- **The Discord rival's 48fps was NOT lsfg-style insertion at ~24 base.** He runs an
  **Odin 3 ULTRA (Cliff has a MAX — different SKU!)**: 41 fps with upscaling off,
  ~48 with FSR3.1. His native is ~2x ours — SKU-normalize before treating 41 as a
  reachable target. The display-path-ceiling investigation is reopened with this as
  a hard reference, but DON'T assume software owes us 2x.
- Also false accusations along the way, each individually exonerated by test:
  kernel-18 (innocent — crashes began on -17), the re-downloaded depot content
  (bit-identical manifests), the lsfg host manifest (quarantined+restored), UFS
  storage (timestamp-attr spam exists on -17 too; reads clean at 393MB/s — the
  log spam every ~5s is a known-benign nuisance, DO NOT chase it as a crash cause),
  mesa shader cache, Steam client (probably — see open questions).

### TRAPS

- **pgrep/pkill -f struck SIX times this session** (killed my own test loop; nearly
  faked a game-running check; plausibly killed the gamescope session at 16:30 —
  black screen + dead power button). Bare `pkill`/`pgrep -x` ONLY over ssh. If the
  screen goes black with ssh alive: `systemctl restart getty@tty1` respawns the
  whole session cleanly — no power-hold needed.
- **This Proton names the game's main process comm "GameThread"** — monitors matching
  "Cyberpunk"/exe names see nothing. Watch GameThread. Games also often SIGSEGV
  during normal EXIT under FEX (teardown crash, coredump present, user saw nothing
  wrong) — a coredump alone does not mean the game "crashed" mid-play.
- **deck's UID is 1001, not 1000** — wpctl/systemctl --user via sudo need
  XDG_RUNTIME_DIR=/run/user/1001, else "no sinks"/"Failed to connect" lies.
- ssh'd FEX runs need `nsenter -t $(pgrep -x FEXServer) -m` (session FEXServer
  mounts the rootfs in a private namespace). vulkaninfo/vkcube without a display are
  crashy under thunks — judge by real games only. Also lsfg-vk auto-writes
  ~/.config/lsfg-vk/conf.toml whose EXAMPLE profiles match vkcube by name (4x FG!) —
  it sabotaged our own vkcube tests.
- Steam uninstall+reinstall is NOT a clean slate: prefix (compatdata), shadercache,
  Steam Cloud, AND /etc/pocknix/game-tweaks.json all survive. Scorched-earth list =
  all four + userdata/<id>/<app> cloud mirror (backups of Cyberpunk's are in /root/).
- The engine-level GamePipelineLibrary.cache (in the game's CDPR AppData) is a
  SECOND pipeline cache under vkd3d-proton.cache — purge both or neither.
- Benchmark/overlay fps ≠ presented fps when frame-gen is active (either kind).

### NEXT (ordered)

1. **Release image rebuild** — everything is in localrepo now (kernel-18, bsp-13,
   steam-38, decky-13, lsfg-vk, fex-emu w/ ThunksDB fix). Decide the Steam client
   channel first (repo still pins publicbeta; device runs stable happily — my vote:
   ship stable, keep beta as a documented opt-in). Then HOLODOR_RELEASE=1 build,
   spot-check, SourceForge upload (project exists; Cliff has creds).
2. **lsfg presented-rate verification** — confirm insertion actually doubles
   presents under gamescope (gamescopectl / heavy-game feel test with a sub-30fps
   base), then re-test the THUNK route with TSO on (see WRONG) and settle the
   b95cb53 guest-vs-thunk default. Needs: game at low base fps, eyes on panel.
3. **Android-boot recovery** (blocks the jack-DETECT question only; shipping mode
   is manual switching regardless). Loop is pre-init (AYN→vibrate→black). Userdata
   is now properly f2fs (that bug is fixed). Recon in memory: misc BCB clean,
   boot LUN = /dev/sde, slot attrs boot_a=0x00F3/boot_b=0x0077 (QC bit layout
   unverified — research gpt-utils for the sun platform before poking). Experiment:
   restore STOCK abl to ONE slot from BONESAW backups (⚠ on-device /sdcard copies
   were destroyed with userdata; offline copies + sha256s per memory 2026-07-26).
   EDL/QFIL = ABSOLUTE last resort (rawprogram repartitions sda = destroys Holodor).
4. **fps-ceiling hunt, reopened** — 21.5 native vs Ultra's 41: first SKU-normalize
   (what SoC/clocks does the Ultra actually have?), then the display-path theory
   gets its rematch. Cheap first probe: ask the Discord guy for HIS native number
   at identical settings + what panel refresh Armada runs.
5. Small: right-ear idle hiss (codec noise floor vs no-suspend tradeoff);
   UFS timestamp-attr log spam (cosmetic silencing patch?); fex-emu pkgrel not
   bumped for the ThunksDB change (same-version repackage — bump on next real
   rebuild); Hades vkd3d cache still has a .poisoned-bak sibling; PROTON_LOG env
   probably still in Cliff's Cyberpunk launch options — REMOVE before fps runs.

### Open questions

- Does MBHC jack-detect work in AYN's Android? (Blocked on #3. If Android doesn't
  detect either, the hunt ends as platform parity.)
- Was the Steam client update (1786491548, publicbeta, 08-12 11:17) contributing
  instability at all, or 100% innocent? We rolled back mid-saga so it was never
  cleanly A/B'd against TSO-on. Device runs stable-channel now either way.
- Ultra vs Max SKU delta (clocks? cooling? RAM?) — determines how much of the
  41-vs-21.5 gap is silicon.
- Why did Cliff set global "fast"? (Probably while exploring the new Games tab —
  consider making the global preset harder to change accidentally, or defaulting
  per-game-only.)

— written 2026-08-14 by **Claude Fable 5** (session: jack day / TSO saga / lsfg bring-up)

## STATE 2026-08-08 (historical)

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

HEADPHONE JACK STATUS AT 2026-08-13 ~02:00 CLOSE — **AUDIO THROUGH THE JACK WORKS**
(vendor-DTB + vendor-driver archaeology paid off; full story in project memory
2026-08-13 entry). Short version: AYN's DT = "Sun QRD SKU1" overlays in stock dtbo;
jack = dedicated 3.5mm, classic MBHC; vendor wcd_usbss C source recovered (NothingOSS/
OnePlusOSS GitHub) — source+analysis PRESERVED IN REPO at
docs/reference/vendor-archaeology/ (method writeup + extraction tools in
tools/vendor-archaeology/ — reusable for every remaining bring-up gap + RP6); vendor HSJ sequence
hand-poked on hw -> TONE IN HEADPHONES (right channel only — left-channel bug open,
kernel-18's full vendor sequence may fix). Kernel-18 BUILT (0610 v4 = hw-validated
vendor HSJ program; 0611 typec stale-handle crash guard — the oops that faked 0%
battery + wedged glink/audio + hung shutdown, see memory; DTS qcom,usbss phandle).
DEPLOY CEREMONY PENDING: build-packages.sh linux-pocknix-sm8750 -> verify v4 symbol in
Image (System.map: wcd939x_usbss_vendor_hw_init) -> pacman -U -> reboot -> jack test
protocol (charger OUT first!). MBHC DETECT still zero even in full vendor state with
audio flowing — sense pin may be unwired; DECISIVE NEXT TEST = boot stock Android
(dual-boot), plug headphones, does it auto-switch? Never tested. If Android doesn't
detect either -> manual switching is platform parity, detect hunt ends.
AUDIO CONFIG LANDMINES found tonight (repo UCM has partial fixes, pkgrel 12
uncommitted-to-localrepo): (1) Headphones sink priority 200 > Speaker 100 = Headphones
becomes DEFAULT sink now that the sink exists (bsp-11) — repo UCM sets 90; (2) q6apm
DSP feeds ONE BE per FE stream — stray 'SECONDARY_MI2S_RX Audio Mixer MultiMedia2'=on
starves the codec BE ("Headphones" plays from speakers); (3) WirePlumber JackControl
gating marks Headphones sink unavailable while detect is dead (streams silently move to
default — watch sink state=suspended); (4) MY repo UCM edits break boot-time MM1
routing (boot comes up silent — one of 4 diffs vs original is culpable, BISECT before
shipping bsp-12; original UCM boots fine); (5) something re-defaults the sink to
Headphones despite wpctl set-default — suspect Steam's own remembered output device;
(6) Steam UI shows NO output selector on this build — fallback plan: sink switcher in
Pocknix Control QAM plugin. Device left on kernel-17, ORIGINAL UCM, headphones-default
quirk live (sound goes to jack if plugged, else speakers after manual set-default).

2026-08-13 DAY SESSION RESULTS (docket items 1-2 + Cyberpunk track DONE):
(1) ✅ kernel-18 DEPLOYED + VALIDATED: clean boot, shutdown no longer hangs, battery
gauge sane, tripwire empty, PLUGGED-IN suspend soak 3/3 clean (deep entry/exit,
charged 81->97% through it). NOTE: wcd939x_usbss_vendor_hw_init is static+inlined —
NOT in System.map (verify via strings on the .o); commit 63bfae6 documents it.
(2) ✅ boot-silence ROOT-CAUSED + FIXED (bsp-13, 5cf8012): q6apm quirk — writing 0
to any FE route on a backend RESETS that BE's mixer and drops its other FE routes;
the verb's MM2-clear ran after the MM1-set and wiped it every boot. Clear-first
ordering fixes it; hw-verified through full WirePlumber apply + playback.
(4) ✅ Cyberpunk 48fps DEMYSTIFIED: our FEX defaults are IDENTICAL to the Armada
panel (and a per-game FEX preset pipeline already existed: Games tab ->
game-tweaks.json -> proton-wrapper -> FEX_APP_CONFIG). His 48fps = lsfg-vk frame
insertion (~24fps base x2). SHIPPED (1e5b5c1+cbf1c59, all deployed to device):
packages/lsfg-vk (upstream develop @8b0da266 — layer verified in vulkaninfo),
wrapper LSFGVK_* env + per-launch ThunksDB.Vulkan flip, Frame Insertion toggle +
multiplier + six Armada-parity per-flag FEX toggles in Pocknix Control.
⚠ lsfg REMAINING (the hard part): fex-emu PKGBUILD pkgrel-2 comment = thunks don't
engage on our Arch guest rootfs (@PREFIX_LIB@ mismatch) AND pressure-vessel captured
thunk STUBS -> FEX segfault = almost certainly Cliff's frame-insertion crash. Bring-up
order in task list: native-arm64 layer proof -> guest overlay path fix -> stub-capture
fix inside SLR (ROCKNIX prior art: layer json into pressure-vessel overrides). Needs
Lossless Scaling OWNED + installed on device (reads Lossless.dll; ask Cliff).
EVENING/NIGHT SESSION (2026-08-13/14) — read project memory for full detail:
✅ JACK LISTEN TEST PASSED: stereo correct, both channels full (left was PHYSICAL
plug seating — reseat+twist; right-ear idle hiss = polish item). ✅ THE CYBERPUNK
CRASH SAGA SOLVED: global fexProfile "fast" (TSO OFF) was corrupting heavy
multithreaded games — restored default, 20min+15min soaks clean; "Fast" preset
relabeled unstable (300c2be); every other suspect exonerated along the way (kernel-18,
game content, client — device now on Valve's STABLE arm64 client 1785799196 which now
exists; launcher publicbeta pin sed-patched ON DEVICE, repo pin decision pending).
Cyberpunk benchmark 720p low: 21.5 native, 25.6 w/ FSR3.0 upscale, 34.28 w/ FSR3.1 +
in-game FSR3 frame gen (WORKS now — TSO was why it crashed). Discord rival = Odin 3
ULTRA (different SKU!) at 41 native — SKU-normalize before treating as target; native
gap = reopened fps-ceiling hunt with a hard reference. lsfg benchmark counter reads
BASE fps (insertion invisible to it) — presented-rate verification pending.
❌ ANDROID DUAL-BOOT BROKEN (new project: android-boot recovery): bootloop predates
tonight (possibly since the July ABL flash — never tested). Fixed installer bug
(userdata left RAW — now f2fs) but loop is EARLIER (AYN→vibrate→black). Plan + GPT
slot recon in memory. ⚠ on-device abl backups destroyed w/ userdata (offline copies
on BONESAW intact). Jack-DETECT test still blocked on it (shipping mode = manual
switching regardless). STILL OPEN: BT latency + controller (v2), release image
rebuild (now incl. bsp-13, steam-38, decky-13, lsfg-vk, fex-emu ThunksDB, client
channel decision).

Session history below:

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
