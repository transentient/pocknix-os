# Installing Holodor on the AYN Odin 3

Holodor turns your AYN Odin 3 into a SteamOS-style handheld - Valve's own Holo Core
system, the ROCKNIX kernel, and a Steam Big Picture session that boots in seconds.
Android stays on the device; you choose what boots.

**Fair warning**: this involves flashing a bootloader payload to your device. The
procedure preserves Android and is reversible, but read every step BEFORE starting,
and DO NOT SKIP THE BACKUP STEP.

---

## What you need

- An **AYN Odin 3** (any storage size) on stock Android
- A **microSD card, 32 GB minimum** (64 GB+ recommended if you'll install games to it)
  - ⚠️ **The bootloader is extremely picky about SD cards.** Older, boring cards
    (e.g. SanDisk Ultra class) work; many fast modern cards (high-end UHS-I/A2) are
    simply invisible to it. TEST YOUR CARD FIRST (Part B, step 1) before spending
    20 minutes flashing an image to a card the device can't boot.
- A **PC** (Linux/Mac/Windows) with an SD reader, to flash the image
- The **Holodor image** (see Releases) and the **ROCKNIX ABL package** (link in
  Releases notes)

---

## Part A - One-time bootloader setup (ROCKNIX ABL)

The Odin 3 ships with a bootloader that only boots Android. ROCKNIX publishes a
replacement bootloader payload ("ABL") that adds a boot menu: Android or Linux-from-SD.
Flashing it does NOT unlock, wipe, or modify Android - it replaces only the small
`abl` bootloader partitions, and you will back those up first.

**A.1 - Get the files onto the device.** Download the ROCKNIX ABL release for the
Odin 3 (SM8750) and copy its folder to your device's internal storage so the files
sit at: `/sdcard/rocknix_abl/SM8750/` - it must contain `backup_abl.sh`,
`flash_abl.sh`, `restore_backup_abl.sh`, and the signed ABL image. [VERIFY: exact
release URL + file list on dry run]

**A.2 - BACK UP YOUR BOOTLOADER.** In Android: **Settings → Handheld Settings →
Run Script as Root** [VERIFY: exact menu names], select `backup_abl.sh`, run it.
- ⚠️ The script runner ALWAYS reports success, even when it did nothing. VERIFY the
  backup exists: check that `/sdcard/rocknix_abl/SM8750/` now contains `abl_a.img`
  and `abl_b.img` (about 1 MB each).
- **Copy those two files to your PC as well.** There is NO published stock Odin 3
  bootloader anywhere - these files are your only way back to a clean stock state.
  Treat them like your passport.
- ⚠️ Do NOT edit any of these scripts. The runner executes them one line at a time -
  edits that look harmless will silently break them.

**A.3 - Flash the ROCKNIX ABL.** Same menu, run `flash_abl.sh`. Again verify by
outcome, not by the success message: reboot while holding **Volume-Down** - you
should land in a text boot menu (the ROCKNIX ABL). If you get plain Android, the
flash didn't take; re-run.

**A.4 - Configure the boot menu** (one time): in the ABL menu, set **device model:
AYN Odin 3**, and leave boot mode on Android for now. "System Stats" in this menu
is also your SD card compatibility tester.

**Going back to Android at any time**: ABL menu → boot mode → Android. Full undo of
everything: run `restore_backup_abl.sh` the same way you ran the others.

---

## Part B - Flash the Holodor image to SD

**B.1 - Test your card FIRST.** Put the (still-empty) card in the Odin 3, boot to
the ABL menu (hold Volume-Down), open System Stats. If it shows an SD card: good.
If it says no card: the bootloader can't see that card - use a different (usually
older/slower) one. Do not bother flashing a card that fails this test.

**B.2 - Flash.** On your PC, write the image to the card:
- Linux/Mac: `zstd -d holodor-*.img.zst` then
  `sudo dd if=holodor-*.img of=/dev/sdX bs=4M conv=fsync status=progress`
  (triple-check /dev/sdX - this destroys the target disk!)
- Windows: decompress, then flash the .img with **Rufus** or **balenaEtcher**.

**B.3 - Boot it.** Card into the Odin 3 → power on holding **Volume-Down** → boot
mode **Linux** → Start.

---

## Part C - First boot: what to expect

1. A brief boot splash. First boot takes a little longer: the system expands itself
   to fill your SD card automatically.
2. **Holodor downloads Steam on first boot** (about 350 MB - the image doesn't
   include it). A status screen tells you what's happening. It needs Wi-Fi, and
   there's no on-screen keyboard yet at this point, so give it your network one of
   these ways:
   - **The wifi.txt way (recommended):** before first boot - or whenever the screen
     asks - put the SD card in your computer and create a file called `wifi.txt` on
     the small partition (the one your computer can see), containing:

     ```
     ssid=YourNetworkName
     password=YourWifiPassword
     country=US
     ```

     (`country` is your two-letter country code; optional, but 5 GHz networks won't
     connect without it.) Put the card back and power on. After it works, the file
     is renamed `wifi.txt.imported`; if something's wrong with it, the reason is
     written to `wifi-import-error.txt` on the same partition.
   - Or plug in a **USB keyboard/dock** and use a wired connection or a terminal.

   The download is safe to interrupt - powering off mid-download just resumes on
   the next boot.

   **Expect a wait here, especially on slower cards.** Holodor's image doesn't
   include Steam - on first boot it downloads the official client from Valve and
   lets it set itself up, so the image ships no Valve software and you always
   start with a current client. (ArmadaOS takes the other approach and bakes
   Steam into its image, which makes its first boot faster.) The download itself
   is about 350 MB, but the setup step after it writes thousands of small files,
   and its speed depends almost entirely on your SD card: a few minutes on a
   fast card, possibly 30-60 minutes on a slow one. The status screen always
   says what it's doing - if it says it's working, it is.
3. Once Steam is downloaded you'll be asked to pick your **Wi-Fi network** (already
   connected if you used wifi.txt) and then land in Steam's setup.
4. **Sign in to Steam.** ⚠️ Right after sign-in, Steam downloads and applies an
   update to itself in the background, and until that finishes the interface is
   genuinely unpleasant: menus lag, button presses respond late, you may see a
   spinner or a "connection problem" message once or twice, and the storage
   grinds constantly. On a slow SD card this can last 10-20 minutes. Nothing is
   broken, and it only happens around the first sign-in - let it finish, and
   once the grinding stops the interface snaps back to normal.
5. You're in Big Picture. Controls, sound, rumble, and the stick RGB should all work
   out of the box. Enjoy.

**Sleep works**: short-press power to suspend (measured standby drain: well under
1%/hour). Fan curves and power profiles (Eco/Balanced/Performance) live in
**Quick Access → Decky → Pocknix Control → Power**. The battery charge limit
setting there is **experimental** - the device may charge past the limit.

---

## Part D - Optional: install to internal storage

Running from internal UFS storage is faster than any SD card. The installer shrinks
Android's data partition and installs Holodor beside it - **Android survives but is
FACTORY RESET** (its apps/data are wiped; the OS remains bootable from the ABL menu).
Your Android bootloader backup from A.2 remains your deep-recovery option.

1. Boot Holodor from SD, connect Wi-Fi.
2. Switch to Desktop Mode or SSH in [VERIFY: document the exact path for
   non-SSH users], open a terminal, and run: `sudo pocknix-install-internal`
3. Choose how much space Android keeps (32 GB is a sensible minimum). Type `INSTALL`
   when prompted. The copy takes ~20–30 minutes.
4. Power off, REMOVE THE SD CARD, power on. Holodor now boots from internal storage.
   Keep the SD card - it remains a bootable rescue system. [VERIFY: boot order with
   SD inserted]

---

## Troubleshooting

- **ABL menu says "SD card not inserted"** - your card is one the bootloader can't
  see. Use an older/slower card. (The card is fine for other uses.)
- **"ERROR: Payload not found" when setting device model** - same cause as above:
  the ABL can't read the card the payload lives on.
- **Stuck at Steam sign-in with a spinning QR code** on first boot - wait 2–3
  minutes (clock sync + client update). If it persists past ~10 minutes, hold power
  15s and boot again; the second attempt is clean.
- **Wi-Fi shows connected but nothing loads** (yellow dot on the network icon) -
  toggle Wi-Fi off/on in Settings. Recent builds do this for you automatically
  after sleep.
- **A game froze and buttons are dead** - short-press power to sleep, press again to
  wake; the menu usually recovers. Known issue with the in-game Steam overlay in
  some titles; opening the game's own pause menu first avoids it.
- **Something is truly wedged** - hold power 15 seconds; the system boots clean and
  is designed to recover (filesystem journaling + boot fallbacks).

## Known limitations (honesty section)

- Heavy AAA titles currently run around **20–30 fps** - the GPU driver for this
  chip is young and improving month to month. Upscaling (FSR) and frame
  generation can make games feel noticeably smoother than the raw number
  suggests. Indie/2D/light-3D titles run flawlessly at high framerates.
- Games with kernel anti-cheat (e.g. Elden Ring's EAC) do not run yet.
- Suspending while a game is running may disconnect the controller in-game (exit to
  Steam first for reliable in-game suspend).
- The battery **charge limit** setting is experimental: the hardware doesn't always
  honor it, and the device may charge to 100% anyway.

---

## Appendix: enabling SSH / setting passwords (tinkerers)

Release images ship the Steam Deck way: no passwords exist and SSH is off - there is
nothing to attack until you opt in. To enable remote access:

1. Switch to Desktop Mode, open a terminal (Konsole).
2. `passwd` - set a password for the `deck` user (it will not ask for an old one).
3. `sudo systemctl enable --now sshd` - SSH is now on, key or password auth as you
   configure it. (`sudo passwd root` first if you want direct root SSH; better:
   ssh in as deck and use sudo.)
