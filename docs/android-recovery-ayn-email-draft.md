# Draft: email to AYN (lucia@ayn.hk) — Android won't boot after dual-boot setup

Context for Cliff: Lucia shared the EDL package in July. She/the AYN team built this
ABL and know its Android boot flow. This is the single fastest path to a real answer.
Keep it short and precise — engineers respond to precise bug reports.

---

**Subject:** Odin 3 — stock Android won't boot after Linux dual-boot (bootloader-level, need one hint)

Hi Lucia,

Thanks again for the EDL package in July — it's been invaluable. I've been running a
Linux dual-boot on my Odin 3 and hit a bootloader-level puzzle I'm hoping someone on
the AYN/Qualcomm side can shortcut for me.

**Symptom:** Stock Android bootloops — AYN logo → vibrate → black → repeat, never
reaching init. Linux boots fine on the same device.

**What I've already ruled out (all tested):**
- Both slots' full Android chains (boot, init_boot, vendor_boot, dtbo, vbmeta,
  vbmeta_system, recovery) verify byte-perfect with avbtool against the signed vbmeta.
- I rebuilt slot A completely from your Dec-2025 EDL package (byte-verified) — still bounces.
- `fastboot boot boot.img` (RAM boot, bypassing all partition state) ALSO fails —
  "Booting OKAY" then straight back to the menu, no display.
- Both the stock AYN ABL and a modified ABL fail identically.
- Device is UNLOCKED (+critical), Secure Boot OFF, slot healthy (retry 6, not unbootable).

Because RAM boot fails and two independent full firmware sets fail, this isn't
partition content — it's something in the boot-time environment the ABL builds for
Android. The UEFI log never prints "Booting Into Mission Mode"; it goes
`Fastboot=0, Recovery:0 → SilentBoot Mode:11 → No \EFI\BOOT\BOOTAA64.EFI → fastboot`.
XBL reports `Platform: HDK, Subtype 1, Chip Ver 2.0`. I've also confirmed the AVB
persistent-value path (avb.managed_verity_mode in devinfo) reads and writes cleanly,
so it isn't an AVB I/O abort. That leaves the DTB/DTBO platform selection and the
pvmfw/AVF path as the prime suspects.

**My questions:**
1. What state does the ABL check between XBL hand-off and "Booting Into Mission Mode"?
   Is there a pvmfw / vm-bootsys / pKVM (AVF) load or verify step that would silently
   abort Android pre-init if it fails — a step Linux boot wouldn't hit?
2. Should "Platform: HDK" appear on a retail Odin 3, or should it read something else
   (QRD/MTP)? Could a platform/board-ID mismatch cause the ABL to pick the wrong DTB/DTBO
   overlay (or none) and skip Mission Mode? On boot-header-v4 the boot.img has no DTB,
   so the ABL's overlay selection is load-bearing — which dtbo entry should a retail
   Odin 3 land on?

The device is fully backed up and I'm comfortable at the fastboot/dd/EDL level — I just
need to know which door to look behind. Any pointer saves me days.

Thanks so much,
[Cliff's sign-off]

---

## Companion: Odin 3 Linux Discord question (post alongside)

> Has anyone actually dual-booted **stock Android** via rocknix-abl on an **Odin 3**
> (not Odin 2) — specifically *after* doing the internal install? Mine bootloops (AYN
> logo → vibrate → black, never hits init) while Linux boots fine. I've verified every
> Android image with avbtool, rebuilt a slot fully from the Dec-2025 EDL package, and
> even `fastboot boot boot.img` (RAM boot) fails — so it's not partition content, it's
> something in the ABL's Android hand-off. UEFI log never shows "Booting Into Mission
> Mode". If anyone boots Android on an Odin 3 this way, could you grab your
> `/logfs/UefiLog*.txt` and your abl version? Trying to figure out if this is
> universal on the Odin 3 or something about my device state. 🙏
