# Installing Holodor

These instructions are for the **AYN Odin 3**, the only device Holodor supports today.
Other devices will get their own sections when they are supported.

Holodor turns the Odin 3 into a SteamOS-style handheld: Valve's own Holo Core system,
the ROCKNIX kernel, and a Steam Big Picture session that boots in seconds. 

There are two ways to run it:

- **From the SD card.** Good for trying it out. The Android install is not changed at all.
  Running this way is, however slower than internal storage, and some cards may not work
  (see below).
- **Installed to internal storage, alongside Android.** The real way to run Holodor.
  Runs fast. Android stays bootable from the boot menu. Note: your Android install is
  factory reset once.

Both ways need the one-time boot menu setup in Part II. Read every part before starting.
Do not skip the backup step.

**Expect the first hour to be rough.** Holodor does not ship with Steam. On first boot it
downloads the Steam client, and right after you sign in Steam updates itself again. Until
that finishes, menus lag, button presses respond late, and the storage grinds, especially
on an SD card. Nothing is wrong. It happens once. Part III says what to expect step by
step.

**One download.** Everything you need is in the Holodor image. The bootloader files are
on the SD card once you have written it.

---

## What you will need

- An **AYN Odin 3** (any storage size) on stock Android
- A **microSD card, 32 GB minimum** (64 GB or more if you will install games to it)
  - The bootloader is picky about SD cards. Older, plain cards (for example SanDisk
    Ultra) work; many fast modern cards (high-end UHS-I or A2) are invisible to it.
    Part II step 8 tells you whether yours works. If it does not, use a different card;
    the card itself is probably fine for other uses.
- A **PC** (Linux, Mac or Windows) with an SD card reader
- The **Holodor image**: one file. Current release:
  https://holodor.bonesaw.com/holodor-odin3-20260918c-seedless.img.zst (3.2 GB).
  Its checksum file is
  https://holodor.bonesaw.com/holodor-odin3-20260918c-seedless.img.zst.sha256.
  Check the download against it before writing the card.

---

## Already running ArmadaOS or ROCKNIX? Read this first

ArmadaOS and ROCKNIX use the same ROCKNIX bootloader as Holodor. If one of them is on
your Odin 3, you already have the boot menu, and Holodor fits in next to it or in its
place. Differences from a stock device:

- **Skip most of Part II.** The bootloader is flashed and the device model is set. Only
  step 9 (turn off Android updates) still applies if you have not done it.
- **Bring your bootloader backup with you.** When you flashed the bootloader, the kit
  wrote your stock bootloader backup to a `rocknix_abl/SM8750` folder on that SD card
  (and to Android's internal storage, which the Armada or ROCKNIX install then wiped).
  Before Part II, copy `abl_a.img` and `abl_b.img` from that card, or from your PC,
  into the `rocknix_abl` folder on the Holodor SD card. Holodor then keeps them on the
  device, and can put the stock bootloader back from Linux later (Part V). If you skip
  this, Holodor tells you so at install time, and you can point it at the files later,
  on a USB drive or a folder you choose.
- **Trying Holodor from the SD card** is the same as for everyone: Part I, then Part
  III. If Armada or ROCKNIX is on internal storage, the boot menu decides whether the
  card or internal storage boots. Hold Volume Down at power on and look at the boot
  mode setting; choose the SD card. (The exact menu names differ between bootloader
  versions; ArmadaOS installs version 1.1.8, the Holodor card carries 1.1.7. Do not
  flash the Holodor card's bootloader over a newer one.)
- **Replacing Armada or ROCKNIX on internal storage with Holodor** is Part IV. The
  installer sees the existing install and offers **Replace with Holodor**. It reuses
  exactly the space the other system had. **Android is not touched**: not resized, not
  reset, and it keeps its apps. Everything in the Armada or ROCKNIX install is erased,
  so move any saves you care about first.
- **Going back to ArmadaOS.** Armada's installer, as of its 20260907 release, replaces only
  layouts it recognises by partition name (its own and ROCKNIX's) and refuses Holodor's.
  Until Armada ships its newer installer, which replaces any layout, go back through the
  boot menu: **UNINSTALL CFW & EXPAND USERDATA** removes Holodor and gives the space to
  Android (Android is factory reset by that), then install Armada from its card as new.
- **All three at once** (Android, ArmadaOS and Holodor on internal storage) is not
  possible today: the boot menu boots one Linux from internal storage. Keep the other
  one on an SD card, or use Replace to swap which one is internal.

---

## Part I - Download the image and write it to the SD card

1. Download the Holodor image and its checksum file (the two addresses are in "What
   you will need"). Check the download: on Linux or Mac, put both files in the same
   folder and run `sha256sum -c holodor-odin3-20260918c-seedless.img.zst.sha256`; on
   Windows, run `certutil -hashfile holodor-odin3-20260918c-seedless.img.zst SHA256`
   and compare the result with the text in the checksum file by eye.

2. On your PC, write it to the card:
   - Linux or Mac: `zstd -d holodor-*.img.zst` then
     `sudo dd if=holodor-*.img of=/dev/sdX bs=4M conv=fsync status=progress`
     (check /dev/sdX three times: this erases the target disk)
   - Windows: decompress, then flash the .img with **Rufus** or **balenaEtcher**.

   If your tool offers to verify the write, let it. Cards can drop data during a long
   write and still report success.

3. When it is done, your PC shows a small partition on the card. It contains a folder
   called `rocknix_abl`. That folder is the bootloader kit for Part II; leave it there.

---

## Part II - Prepare Android and set up the boot menu (one time)

The Odin 3 ships with a bootloader that only boots Android. ROCKNIX publishes a
replacement bootloader ("ABL") that adds a boot menu: Android, or Linux from the SD card
or internal storage. Flashing it does not unlock, wipe or modify Android. It replaces
only the two small `abl` partitions, and you back those up first.

**What you will have at the end:** a boot menu when you hold Volume Down at power on, a
backup of your original bootloader on the SD card, and Android exactly as it was.

1. **Remove your Google account and any screen lock.** In Android: Settings >
   Passwords, passkeys & accounts > your Google account > Remove account. Then Settings
   > Security > Screen lock > None. You can add them back after Holodor is installed.

   Why: Android keeps a hidden "this device belongs to someone" marker while an
   account or lock exists. After a factory reset, Android then asks for the old
   account, and the Odin 3's setup screen cannot accept it, so Android locks itself
   out. Holodor's installer detects this marker and offers to clear it, but the
   cleanest start is to remove the account first.

2. **Decline Android system updates.** If Android offers an update, do not install it.
   An Android update on a dual-boot device replaces the bootloader on one side and
   broke Android on our test device. Step 9 turns the update app off for good.

3. **Put the SD card in the Odin 3** with Android running. Android may show a
   notification about the new card; choose to use it as portable storage if asked.

4. **Copy the bootloader folder to internal storage.** Open the **Files** app, open the
   SD card, and copy the whole `rocknix_abl` folder to the top level of the internal
   storage, so that `Internal storage/rocknix_abl/backup_abl.sh` exists.

5. **Back up your bootloader.** Open **Settings > Odin settings** (it is near the bottom
   of the Settings list, under "Google"), scroll to the bottom, and tap **Run script as
   Root**. Pick `Internal storage/rocknix_abl/backup_abl.sh` and run it.

   - The script runner always reports success, even when it did nothing. Check the
     result yourself: in the Files app, the `rocknix_abl` folder on the **SD card** must
     now contain `abl_a.img` and `abl_b.img`, 1 MB each. The copy on internal storage
     has them too.
   - Copy those two files to your PC as well. There is no published stock Odin 3
     bootloader anywhere. These files are your way back to a clean stock device.
     Holodor keeps them on the SD card and, after an internal install, inside the
     device too, but a copy on your PC costs nothing.
   - Do not edit any of the scripts. The runner executes them one line at a time, and
     edits that look harmless break them silently.
   - "Enter setup wizard" sits a few rows above "Run script as Root". Do not tap it; it
     restarts Android into the first-time setup.

6. **Flash the ROCKNIX bootloader.** Same menu, run `flash_abl.sh`. Again, trust the
   outcome, not the success message.

7. **Check it took.** Power off (Power menu > Power off, then wait ten seconds). Hold
   **Volume Down** and press Power. You should land in a text boot menu. If plain
   Android starts instead, the flash did not take: repeat step 6.

   The Volume Down trick only works from a powered-off device. From running Android
   it is just a normal reboot.

8. **Set up the menu and test your card.** In the boot menu set the **device model** to
   **AYN Odin 3**, and open **System Stats**. If it shows an SD card, your card works.
   If it says no card is inserted, the bootloader cannot see this card: repeat Part I
   with a different (usually older or slower) card. Android can read every card, so
   the steps above worked; only booting needs the other card.

9. **Turn off Android updates (recommended).** Boot Android (boot mode Android in the
   menu), and run `disable_android_updates.sh` the same way as the other scripts. This
   disables AYN's update app; `enable_android_updates.sh` turns it back on. See step 2
   for why.

**Going back to plain Android at any time:** boot menu > boot mode > Android. Android is
unchanged; only the menu is new. Removing the menu entirely is described in Part V.

---

## Part III - First boot from the SD card

Boot menu (hold Volume Down at power on) > boot mode **Linux** > Start.

1. **A brief boot splash, then a dark screen for up to two minutes.** The system is
   expanding itself to fill the card and starting Steam's setup. The screen is an OLED,
   so "off", "black" and "starting" look the same. **Do not press the power button
   during this wait.** A press puts the device to sleep, which looks even more dead,
   and a long press turns it off. If nothing has appeared after three minutes, hold
   power for fifteen seconds and boot again.
2. **Holodor downloads Steam on first boot** (about 350 MB; the image does not include
   it). A status screen tells you what is happening. It needs Wi-Fi, and there is no
   on-screen keyboard yet at this point, so give it your network one of these ways:
   - **The wifi.txt way (recommended):** before first boot, or whenever the screen
     asks, put the SD card in your computer and create a file called `wifi.txt` on the
     small partition (the one your computer can see), containing:

     ```
     ssid=YourNetworkName
     password=YourWifiPassword
     country=US
     ```

     (`country` is your two-letter country code; optional, but 5 GHz networks will not
     connect without it.) Put the card back and power on. After it works, the file is
     renamed `wifi.txt.imported`; if something is wrong with it, the reason is written
     to `wifi-import-error.txt` on the same partition.
   - **The wired way (no typing at all):** plug in a USB-C hub or dock with an ethernet
     jack, cable attached. The setup waits for any network and carries on by itself.
     Leave it plugged in until Steam is running and has joined your Wi-Fi from its own
     network picker, then unplug it. Do not let the device go to sleep while the hub
     is attached: USB does not come back after that sleep, and you will need a reboot.
   - Or plug in a **USB keyboard** and use a terminal.

   The download is safe to interrupt. Powering off mid-download resumes on the next
   boot.

   **Expect a wait here, especially on slower cards.** Holodor's image does not include
   Steam. On first boot it downloads the official client from Valve and lets it set
   itself up, so the image ships no Valve software and you always start with a current
   client. The download is about 350 MB, but the setup step after it writes thousands
   of small files, and its speed depends almost entirely on your SD card: a few minutes
   on a fast card, possibly 30 to 60 minutes on a slow one. The status screen always
   says what it is doing. If it says it is working, it is.
3. Once Steam is downloaded you will be asked to pick your **Wi-Fi network** (already
   connected if you used wifi.txt) and then land in Steam's setup.
4. **Sign in to Steam.** Right after sign-in, Steam downloads and applies an update to
   itself in the background, and until that finishes the interface is unpleasant:
   menus lag, button presses respond late, you may see a spinner or a "connection
   problem" message once or twice, and the storage grinds constantly. On a slow SD
   card this can last 10 to 20 minutes. Nothing is broken, and it only happens around
   the first sign-in. Let it finish; once the grinding stops the interface snaps back
   to normal.
5. You are in Big Picture. Controls, sound and rumble work out of the box. The
   thumbstick RGB rings are off by default; turn them on in **Quick Access > Decky >
   Pocknix Control** if you want them.

**Sleep works**: short-press power to suspend (measured standby drain: well under
1% per hour). Fan curves and power profiles (Eco, Balanced, Performance) live in
**Quick Access > Decky > Pocknix Control > Power**. The battery charge limit setting
there is **experimental**: the device may charge past the limit.

**Frame insertion**: the **Frame Insertion (LSFG)** toggle in **Pocknix Control > Games**
uses the model from **Lossless Scaling**, a paid Steam app (about 175 MB). Holodor does
not ship it. Buy it on Steam, install it on the device like any game, and the toggle
starts working; until then, turning it on has no effect.

---

## Part IV - Install to internal storage (recommended)

Running from internal storage is faster than any SD card. The installer shrinks
Android's data partition and installs Holodor beside it. **Android survives but is
factory reset**: its apps and data are wiped; the Android system itself stays bootable
from the boot menu. The bootloader and every other Android partition are not touched.

If a Linux system is already on internal storage (ArmadaOS, ROCKNIX, or an earlier
Holodor), the installer offers **Replace with Holodor** instead. That erases the other
system and reuses its space; Android is not resized and not reset. Reinstalling Holodor
over itself works the same way.

1. Boot Holodor from the SD card and connect Wi-Fi.
2. Switch to Desktop Mode (Steam menu > Power > Switch to Desktop) and open
   **Holodor Installer** (application menu > System).
3. Choose **Install Holodor to internal storage**. Pick how much space Android keeps
   (32 GB is a sensible minimum). If Android still carries a Google account marker,
   the installer explains it and offers to clear it; say yes (see Part II step 1 for
   why).
4. Confirm. The copy takes 20 to 30 minutes. Do not power off.
5. Power off, **remove the SD card**, power on. Holodor now boots from internal storage.
   Keep the SD card: it is your rescue system, and the installer app on it is how you
   remove Holodor or restore the stock bootloader later.

**Booting Android afterwards:** hold Volume Down at power on, boot mode Android. Android
will run its first-time setup again. Do not install Android updates (Part II step 2).

The installer keeps your bootloader backup from Part II in three places: on the SD card,
inside the internal install, and on the internal boot partition.

Prefer a terminal? `sudo pocknix-install-internal --dry-run` prints the plan;
`sudo pocknix-install-internal` runs it. See docs/install-to-internal.md.

---

## Part V - Going back to Android, or to a stock device

Three levels, from least to most:

1. **Just boot Android.** Boot menu > boot mode Android. Nothing changes; Holodor stays.

2. **Remove Holodor and give the storage back to Android.** Boot the SD card, open
   Holodor Installer, choose **Remove Holodor**. If you are running Holodor from internal
   storage, the app first offers **Disable internal boot**; do that, power off, boot the
   SD card and open the app again to finish. Android is factory reset once more and
   gets the whole disk back. The boot menu stays, so the SD card still boots.

   Then power off, remove the SD card, boot Android, and let it set up. Make sure it
   works before going to level 3.

3. **Restore the stock bootloader.** Boot the SD card, open Holodor Installer, choose
   **Restore stock bootloader**. It finds your backup from Part II, checks that it really
   is a stock bootloader, clears the Google account marker so Android cannot lock you
   out, writes both slots and reads them back. After this the device boots straight
   into Android; the boot menu and Holodor are gone until you run `flash_abl.sh` from
   Android again. On an unlocked bootloader Android may show a red "device is corrupt"
   screen at boot; if it restarts by itself, a short tap of the power button continues.

**The last resort: AYN's factory firmware.** If Android itself is broken, AYN's EDL
firmware package restores every partition. Three rules, each learned the hard way:

- Flash the **complete** package, every partition, in one go. A partial or mixed flash
  (some partitions from one build, some from another) leaves Android looping at boot.
  Never flash only "the boot image" to fix Android.
- An interrupted flash leaves the device unbootable until a complete flash finishes.
  Do not touch the buttons while it runs; holding power for more than ten seconds
  resets the chip and aborts the flash.
- The factory package does **not** clear the Google account marker (the `frp`
  partition). If Android then shows "Factory reset this device" with only a Reset
  button, erase that partition from the same EDL tool (`edl e frp --memory=ufs
  --lun=0` with the package's loader) and boot again. Holodor's **Fix Android setup
  lock** does the same thing when the boot menu is still present.

The factory flash removes Holodor's partitions and the boot menu. The SD card is not
affected.

---

## Troubleshooting

- **Boot menu says "SD card not inserted"** - your card is one the bootloader cannot
  see. Use an older or slower card. (The card is fine for other uses.)
- **"ERROR: Payload not found" when setting device model** - same cause: the
  bootloader cannot read the card the payload lives on.
- **"DEVICE MODEL NOT SET" after a bootloader update** - set it again (Part II step 8).
- **Android shows "Factory reset this device" and only a Reset button** - the Google
  account marker survived a reset. Boot the SD card, open Holodor Installer, choose
  **Fix Android setup lock**, then boot Android again.
- **Red "device is corrupt" screen that keeps restarting** - normal on an unlocked
  bootloader. A short tap of the power button continues; leaving it alone restarts it.
- **Black screen for a minute or two on first boot** - it is working. See Part III
  step 1.
- **Stuck at Steam sign-in with a spinning QR code** on first boot - wait 2 to 3
  minutes (clock sync plus client update). If it persists past 10 minutes, hold power
  15 seconds and boot again; the second attempt is clean.
- **Wi-Fi shows connected but nothing loads** (yellow dot on the network icon) -
  toggle Wi-Fi off and on in Settings. Recent builds do this for you automatically
  after sleep.
- **A game froze and buttons are dead** - short-press power to sleep, press again to
  wake; the menu usually recovers. Known issue with the in-game Steam overlay in some
  titles; opening the game's own pause menu first avoids it.
- **The device refuses to boot either system and drops to the boot menu** - a slot
  counter ran out. From a PC with fastboot: `fastboot set_active a` (or `b`) from the
  boot menu's fastboot mode. Holodor images keep this from happening on their own.
- **Something is truly wedged** - hold power 15 seconds; the system boots clean and is
  designed to recover (filesystem journaling plus boot fallbacks).

## Known limitations

- Heavy AAA titles currently run around **20 to 30 fps**. The GPU driver for this chip
  is young and improving month to month. Upscaling (FSR) and frame generation can make
  games feel noticeably smoother than the raw number suggests. Indie, 2D and light-3D
  titles run flawlessly at high framerates.
- Games with kernel anti-cheat (for example Elden Ring's EAC) do not run yet.
- Suspending while a game is running may disconnect the controller in-game (exit to
  Steam first for reliable in-game suspend).
- The battery **charge limit** setting is experimental: the hardware does not always
  honor it, and the device may charge to 100% anyway.
- With Holodor on internal storage, a ROCKNIX or ArmadaOS SD card may not boot: on
  bootloader 1.1.7 the internal boot partition wins. Newer bootloaders have a boot mode
  that forces the SD card; check the boot menu. Otherwise the Holodor Installer's
  **Disable internal boot** step (Part V, level 2) makes the card boot, and can be
  undone.
- Only one Linux system can be installed on internal storage at a time (see "Already
  running ArmadaOS or ROCKNIX?" above).
- The boot menu's SD card support is narrower than Android's. A card that Android
  reads fine may still be invisible to the boot menu.

---

## Appendix: enabling SSH and setting passwords (tinkerers)

Release images ship the Steam Deck way: no passwords exist, root is locked, there is no
sudo, and SSH is off, so there is nothing to attack until you opt in. To enable remote
access:

1. Switch to Desktop Mode, open a terminal (Konsole).
2. `passwd` sets a password for the `deck` user (press Enter at the "current password"
   prompt: there is none).
3. `systemctl enable --now sshd` turns SSH on. No sudo is needed: the `deck` user may
   manage services. Log in over SSH as `deck`.
4. For a root shell, from the deck account: `systemd-run --wait --pipe -t /bin/bash`.
   The same rule that lets deck manage services lets it run this.

Command-line equivalents of the installer app: `pocknix-install-internal` (add
`--replace` to take over an existing Linux install without touching Android),
`pocknix-uninstall-internal`, `pocknix-clear-frp`, `pocknix-restore-stock-abl` (add
`--from DIR` to use a backup in any folder). Each prints its plan with `--dry-run`,
`--check` or `--find` before changing anything.
