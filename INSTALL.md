# Installing Holodor on the AYN Odin 3

Two ways to run Holodor:

- **From the SD card.** For trying it out. Android is not changed.
- **On internal storage, next to Android.** Faster. Android stays bootable from the boot
  menu, but is factory reset once by the install.

Both need the one-time boot menu setup in Part II. Do Part I, then II, then III. Part IV
is optional. Already running ArmadaOS or ROCKNIX? Do Part I, then skip to "Coming from
ArmadaOS or ROCKNIX".

The first boot downloads Steam and lets it update itself. Menus lag and the storage
grinds until that finishes. It happens once.

---

## What you need

- An AYN Odin 3.
- A microSD card, 32 GB or larger. The bootloader is picky about SD cards. I had a
  couple of Silicon Power cards that wouldn't work, maybe because they were newer A2
  cards. Part II step 8 tells you whether yours works.
- A PC with an SD card reader.
- The Holodor image: https://holodor.bonesaw.com/holodor-odin3-20260920b-seedless.img.zst
  (3.2 GB) and its checksum file
  https://holodor.bonesaw.com/holodor-odin3-20260920b-seedless.img.zst.sha256.

---

## Part I - Write the SD card

1. Download the image and the checksum file into the same folder.
2. Check the download.
   - Linux or Mac: `sha256sum -c holodor-odin3-20260920b-seedless.img.zst.sha256`
   - Windows: `certutil -hashfile holodor-odin3-20260920b-seedless.img.zst SHA256` and
     compare the result with the checksum file by eye.
3. Write the image to the card.
   - Linux or Mac: `zstd -d holodor-*.img.zst`, then
     `sudo dd if=holodor-*.img of=/dev/sdX bs=4M conv=fsync status=progress`.
     Check `/dev/sdX` three times: this erases that disk.
   - Windows: decompress, then write the `.img` with Rufus or balenaEtcher.
   - If the tool offers to verify the write, let it.
4. Your PC now shows a small partition on the card with a folder called `rocknix_abl`.
   Leave it there. Part II uses it.

---

## Part II - Set up the boot menu (one time, from stock Android)

This flashes the ROCKNIX bootloader, which adds a boot menu: Android, or Linux from the SD
card or internal storage. It replaces only the two small bootloader partitions, after
backing them up. Android is not wiped or modified.

1. Remove your Google account: Settings > Passwords, passkeys & accounts > your account
   > Remove account. Remove any screen lock: Settings > Security > Screen lock > None.
   Reason: with either present, Android locks itself out after the factory reset in
   Part IV. You can add them back after Holodor is installed.
2. If Android offers a system update, decline it. Android updates break dual boot.
3. Put the SD card in the Odin 3 with Android running. If asked, use it as portable
   storage.
4. Open the Files app, open the SD card, and copy the whole `rocknix_abl` folder to the
   top level of Internal storage.
5. Back up your bootloader: Settings > Odin settings (near the bottom, under "Google")
   > scroll to the bottom > Run script as Root > `Internal storage/rocknix_abl/backup_abl.sh`.
   - The runner always says it succeeded. Check: in the Files app, the `rocknix_abl`
     folder on the SD card must now contain `abl_a.img` and `abl_b.img`, 1 MB each.
   - Copy those two files to your PC. There is no other source for the stock Odin 3
     bootloader.
   - Do not edit the scripts. Do not tap "Enter setup wizard" a few rows above.
6. Flash the bootloader: Run script as Root > `flash_abl.sh`.
7. Power off: Power menu > Power off, wait ten seconds. Then hold Volume Down and press
   Power. A text boot menu appears. If Android starts instead, repeat step 6.
8. In the boot menu, open System Stats. If it shows an SD card, your card works. If it
   says no card is inserted, this card cannot be booted from: repeat Part I with a
   different, usually older or slower, card. If the menu has a device model setting,
   set it to AYN Odin 3.
9. Turn off Android updates: choose boot mode Android in the menu, start, and run
   `disable_android_updates.sh` the same way as step 5. (`enable_android_updates.sh`
   turns them back on.)

To boot Android at any time: boot menu > boot mode Android > start.

---

## Part III - First boot from the SD card

1. Hold Volume Down and press Power. In the menu: boot mode Linux. If the menu has a
   boot source setting, choose SD card. Start.
2. Wait. After the boot art the screen is dark for up to two minutes while the card is
   prepared. Do not press the power button. If nothing appears after three minutes,
   hold Power for fifteen seconds and boot again.
3. Give it a network for the Steam download, one of these ways:
   - **wifi.txt:** put the SD card in your PC and create a file called `wifi.txt` on
     the small partition, containing:

     ```
     ssid=YourNetworkName
     password=YourWifiPassword
     country=US
     ```

     (`country` is your two-letter country code, needed for 5 GHz networks.) Put the
     card back and boot. After it works the file is renamed `wifi.txt.imported`; if it
     was wrong, the reason is in `wifi-import-error.txt` on the same partition.
   - **Wired:** plug in a USB-C hub or dock with an ethernet cable. Leave it in until
     Steam is up and has joined your Wi-Fi from its own network settings. Do not let the
     device sleep with the hub attached.
4. The download screen shows its progress. It takes minutes on a fast card, up to an
   hour on a slow one. Powering off mid-download is safe; it resumes on the next boot.
5. Sign in to Steam. Right after sign-in, Steam updates itself. Menus lag and the
   storage grinds for 10 to 20 minutes. Wait for it.
6. You are in Steam. Controls, sound and rumble work. Short-press Power to sleep.

Settings that live in Quick Access > Decky > Pocknix Control: thumbstick RGB (off by
default), fan curves, power profiles, charge limit (experimental), and Frame Insertion,
which needs the paid Steam app Lossless Scaling installed on the device before it does
anything.

---

## Part IV - Install to internal storage (optional, recommended)

The installer shrinks Android's data partition and installs Holodor beside it. Android
is factory reset by this, once. Everything else about Android stays.

1. Boot Holodor from the SD card, with a network connected.
2. Switch to Desktop Mode: Steam menu > Power > Switch to Desktop.
3. Open Holodor Installer: application menu > System > Holodor Installer.
4. Choose **Install Holodor to internal storage**. Pick how much space Android keeps;
   32 GB is a sensible minimum. If the installer offers to clear Android's account
   marker, say yes.
5. Confirm and wait 20 to 30 minutes. Do not power off.
6. Power off. Remove the SD card. Power on. Holodor boots from internal storage.

Keep the SD card. It is your rescue system and the way to remove Holodor later.

To boot Android afterwards: hold Volume Down at power on, boot mode Android. Android
runs its first-time setup again. Decline Android updates.

---

## Coming from ArmadaOS or ROCKNIX

You already have the boot menu, so Part II is not needed, except step 9 if you have not
turned off Android updates.

1. Do Part I.
2. Copy your stock bootloader backup onto the Holodor card: the files `abl_a.img` and
   `abl_b.img` from the `rocknix_abl/SM8750` folder of your Armada or ROCKNIX card (or
   from your PC) into the `rocknix_abl` folder on the Holodor card.
3. Do Part III. In the boot menu, set boot source to SD card; otherwise the internal
   Armada or ROCKNIX boots.
4. To put Holodor on internal storage in place of Armada or ROCKNIX, do Part IV. The
   installer detects the existing install and offers **Replace with Holodor** instead.
   Replace erases that install and uses its space. Android is not resized and not reset.
   Move any saves you care about off the old install first.

You cannot have Android, ArmadaOS and Holodor on internal storage at the same time. Only
one Linux system fits; keep the other on an SD card.

To go back to ArmadaOS later: in the boot menu choose **UNINSTALL CFW & EXPAND USERDATA**
(this removes Holodor and factory resets Android), then install Armada from its card as
new. Armada's current installer does not recognise Holodor's partitions, so it cannot
replace them directly.

---

## Part V - Going back to Android, or to a stock device

1. **Boot Android.** Boot menu > boot mode Android. Holodor stays.
2. **Remove Holodor.** Boot the SD card, open Holodor Installer, choose **Remove
   Holodor**. If Holodor is running from internal storage, the app first offers
   **Disable internal boot**: do that, power off, boot the SD card, and open the app
   again to finish. Android gets the whole disk back and is factory reset. Then power
   off, remove the card, boot Android, and let it set up.
3. **Restore the stock bootloader.** After step 2 and after Android has been seen to
   work: boot the SD card, open Holodor Installer, choose **Restore stock bootloader**.
   It uses the backup on the card, or lets you pick a folder. Afterwards the device boots
   straight into Android and the boot menu is gone. If a red "device is corrupt" screen
   appears and restarts by itself, a short tap of the power button continues.

If Android itself is broken, AYN's factory firmware package restores it. Flash the
complete package, every partition, in one go. Do not touch the buttons while it runs.
If Android then shows "Factory reset this device" with only a Reset button, erase the
`frp` partition with the same tool (`edl e frp --memory=ufs --lun=0`), or use Holodor
Installer > Fix Android setup lock if the boot menu is still present.

---

## Troubleshooting

- **Boot menu says "SD card not inserted":** the bootloader cannot read this card. Use
  an older or slower card.
- **"DEVICE MODEL NOT SET" after a bootloader update:** set it again (Part II step 8).
- **Android shows "Factory reset this device" and only a Reset button:** boot the SD
  card, Holodor Installer > Fix Android setup lock, then boot Android again.
- **Red "device is corrupt" screen that keeps restarting:** normal on an unlocked
  bootloader. A short tap of the power button continues.
- **Black screen for a minute or two on first boot:** it is working. See Part III step 2.
- **Stuck at Steam sign-in with a spinning QR code:** wait 2 to 3 minutes. If it
  persists past 10 minutes, hold Power for 15 seconds and boot again.
- **Wi-Fi shows connected but nothing loads:** toggle Wi-Fi off and on in Settings.
- **A game froze and buttons are dead:** short-press Power to sleep, press again to
  wake. Opening the game's own pause menu before the Steam overlay avoids it.
- **Neither system boots and the boot menu appears every time:** from a PC with
  fastboot, `fastboot set_active a` (or `b`).
- **Anything else wedged:** hold Power for 15 seconds and boot again.

## Known limitations

- Heavy AAA titles run around 20 to 30 fps. Upscaling and frame insertion help. Indie,
  2D and light-3D titles run at high framerates.
- Games with kernel anti-cheat (for example Elden Ring's EAC) do not run.
- Suspending while a game is running may disconnect the controller in-game. Exit to
  Steam first.
- The charge limit setting is experimental; the device may charge to 100% anyway.
- Only one Linux system can be on internal storage at a time.
- The boot menu reads fewer SD cards than Android does.

---

## Appendix: SSH and passwords

The image has no passwords, a locked root, no sudo, and SSH off.

1. Switch to Desktop Mode and open Konsole.
2. `passwd` sets a password for the `deck` user. Press Enter at the "current password"
   prompt.
3. `systemctl enable --now sshd` turns SSH on. Log in over SSH as `deck`.
4. For a root shell: `systemd-run --wait --pipe -t /bin/bash`.

Command-line equivalents of the installer: `pocknix-install-internal` (`--replace` to
take over an existing Linux install), `pocknix-uninstall-internal`, `pocknix-clear-frp`,
`pocknix-restore-stock-abl` (`--from DIR` for a backup in any folder). Each prints its
plan with `--dry-run`, `--check` or `--find` first.
