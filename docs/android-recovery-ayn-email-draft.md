# Draft: email to AYN (lucia@ayn.hk) — Android won't boot after dual-boot setup

Context for Cliff: Lucia shared the EDL package in July. She/the AYN team built this
ABL and know its Android boot flow. This is the single fastest path to a real answer.
Keep it short and precise — engineers respond to precise bug reports.

---

**Subject:** Odin 3 — stock Android won't finish booting after Linux dual-boot (narrowed to post-AVB kernel/init)

Hi Lucia,

Thanks again for the EDL package in July — it's been invaluable. I've been running a
Linux dual-boot on my Odin 3 and I've narrowed an Android boot failure down to what I
think is a kernel/first-stage-init issue I'm hoping someone on the AYN/Qualcomm side can
place quickly.

**Background:** I did an internal install that shrank `userdata` and added two Linux
partitions (leaving all firmware partitions on the other LUNs untouched), and factory-reset
Android. Android then wouldn't boot. I've now traced and fixed the main cause and gotten a
lot further, but it still won't complete.

**What I found and fixed:** the `super` partition still held the older (July) build while I
had reflashed the boot chain + vbmeta to your Dec-2025 EDL images — so the Dec-2025 dm-verity
descriptors were guarding an old filesystem and first-stage init couldn't mount `/system`. I
rebuilt `super` from your Dec-2025 EDL chunks and flashed it (verified byte-perfect by full
read-back), then did the paired `metadata` + `userdata` wipe.

**Where it's stuck now:** Android gets much further — it reaches the AVB stage (the
"device is corrupt / press key to continue" screen), then fails and resets (`PM: Reset by
PSHOLD, Hard Reset`) in a loop. `system_a` verity now passes, so the failure is DOWNSTREAM,
in the kernel or first-stage init. I can't see it: the vendor_boot cmdline is
`console=ttynull`, and there's no ramoops/pstore region I can read from the Linux side.

**Device facts:** UNLOCKED (+critical), Secure Boot OFF. XBL reports `Platform: HDK,
Subtype 1, Chip Ver 2.0`. The live `vbmeta_a`/`vbmeta_system_a`/`boot_a`/`dtbo_a` are
byte-identical to your Dec-2025 EDL; `super` now matches those signatures too.

**My questions:**
1. After first-stage init mounts `/system`, what does the Odin 3's Android boot need next
   that Linux never touches — a pvmfw / pKVM (AVF) bring-up, a vm-bootsys/`vm-persist` step,
   a specific firmware or DSP image, or a `/metadata`-encryption expectation — that would
   PSHOLD-reset if it's not right after a `super` reflash + `-w` wipe?
2. Is there a supported way to get kernel output on a retail Odin 3 (a cmdline/bootconfig
   change you'd recommend, or an armed-ramdump mode) so I can read the panic reason myself?
3. Anything special about flashing Dec-2025 firmware onto a device that shipped on a later
   build — a rollback-index or `/metadata` step I'm missing?

The device is fully backed up and I'm comfortable at the fastboot/dd/EDL level — I just need
to know which door to look behind. Any pointer saves me days.

Thanks so much,
[Cliff's sign-off]

---

## Companion: Odin 3 Linux Discord question (SUPERSEDED 2026-08-15 — Discord was a dead end, nobody bit; and the "never hits init" framing below is now outdated: super was the cause + is fixed, residual is post-AVB kernel/init. Kept for reference only.)

> Has anyone actually dual-booted **stock Android** via rocknix-abl on an **Odin 3**
> (not Odin 2) — specifically *after* doing the internal install? Mine bootloops (AYN
> logo → vibrate → black, never hits init) while Linux boots fine. I've verified every
> Android image with avbtool, rebuilt a slot fully from the Dec-2025 EDL package, and
> even `fastboot boot boot.img` (RAM boot) fails — so it's not partition content, it's
> something in the ABL's Android hand-off. UEFI log never shows "Booting Into Mission
> Mode". If anyone boots Android on an Odin 3 this way, could you grab your
> `/logfs/UefiLog*.txt` and your abl version? Trying to figure out if this is
> universal on the Odin 3 or something about my device state. 🙏
