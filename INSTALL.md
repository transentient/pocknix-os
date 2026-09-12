# Installing Holodor on the AYN Odin 3

**Important Note:** This process requires flashing a bootloader payload to your device. While the procedure preserves your Android setup and is fully reversible, please read all instructions carefully before beginning, and please ensure you do not skip the backup step.

---

## What You Will Need

*   An **AYN Odin 3** (any storage capacity) running stock Android.
*   A **microSD card, 32 GB minimum** (64 GB or larger is recommended if you plan to install games on it).
    *   ⚠️ **SD Card Compatibility:** The bootloader can be selective regarding SD cards. Older, standard cards (like the SanDisk Ultra class) typically work well, whereas some newer, high-speed cards (such as high-end UHS-I/A2) may not be recognized. Please test your card first (see Part B, Step 1) to avoid spending time flashing an image to an incompatible card.
*   A **PC** (Linux, macOS, or Windows) equipped with an SD card reader to flash the image.
*   The **Holodor image** (available in the Releases section) and the **ROCKNIX ABL package** (linked in the release notes).

---

## Part A - One-Time Bootloader Setup (ROCKNIX ABL)

By default, the Odin 3 bootloader only boots Android. The ROCKNIX team provides a replacement bootloader payload (ABL) that introduces a boot menu, allowing you to choose between Android or booting Linux from an SD card. This process does not unlock, wipe, or modify your Android installation. It merely replaces the small `abl` bootloader partitions, which we will safely back up first.

**A.1 - Transfer the files to your device.** Download the ROCKNIX ABL release for the Odin 3 (SM8750). Copy the extracted folder to your device's internal storage exactly at `/sdcard/rocknix_abl/SM8750/`. Ensure this folder contains `backup_abl.sh`, `flash_abl.sh`, `restore_backup_abl.sh`, and the signed ABL image. *(Note: Please verify the exact release URL and file list during your preparation).*

**A.2 - Back up your bootloader.** On your Odin 3 in Android, navigate to **Settings -> Handheld Settings -> Run Script as Root** *(please verify the exact menu names on your device)*. Select `backup_abl.sh` and run it.
*   ⚠️ *Crucial Verification:* The script runner will report success even if the operation fails. You must manually verify the backup by checking that `/sdcard/rocknix_abl/SM8750/` now contains both `abl_a.img` and `abl_b.img` (each should be approximately 1 MB).
*   **Transfer these backup files to your PC.** There are no officially published stock bootloaders for the Odin 3 available online. These files are your only method for restoring the device to its original factory state, so please keep them safe.
*   ⚠️ Please do not edit any of these script files. The system runner executes them line-by-line, and even minor edits can silently break their functionality.

**A.3 - Flash the ROCKNIX ABL.** From the same menu, run `flash_abl.sh`. As before, verify the outcome manually: reboot your device while holding the **Volume-Down** button. You should be greeted by a text-based boot menu (the ROCKNIX ABL). If the device boots directly into regular Android, the flash was unsuccessful, and you should run the script again.

**A.4 - Configure the boot menu** (one time only). In the ABL menu, set the **device model** to **AYN Odin 3**. Leave the boot mode set to Android for the time being. You can also use the "System Stats" option in this menu to verify your SD card compatibility.

**Returning to Android:** At any time, you can return to Android by navigating to the ABL menu -> boot mode -> Android. To completely reverse this installation, run the `restore_backup_abl.sh` script using the same method outlined in A.2.

---

## Part B - Flash the Holodor Image to SD

**B.1 - Test your card first.** Insert your (still-empty) microSD card into the Odin 3. Boot to the ABL menu (by holding Volume-Down) and open System Stats. If it displays your SD card, you are good to proceed. If it says no card is inserted, the bootloader cannot read it, and you will need to try a different (usually older or slower) card.

**B.2 - Flash the image.** On your PC, write the Holodor image to the compatible SD card:
*   **Linux/Mac:** Use `zstd -d holodor-*.img.zst` and then `sudo dd if=holodor-*.img of=/dev/sdX bs=4M conv=fsync status=progress`. *(Please double-check your /dev/sdX path - selecting the wrong drive will erase your data!)*
*   **Windows:** Decompress the file, then flash the `.img` using **Rufus** or **balenaEtcher**.

**B.3 - Boot the system.** Insert the flashed card into the Odin 3. Power on the device while holding **Volume-Down**, change the boot mode to **Linux**, and select Start.

---

## Part C - First Boot: What to Expect

1.  **Boot Splash:** You will see a brief boot splash screen. The very first boot takes slightly longer because the system automatically expands its partitions to fill your SD card.
2.  **Steam Download:** Holodor does not ship with Steam pre-installed to ensure you always start with the most current client. On first boot, it will automatically download the official Steam client (about 350 MB). Because there is no on-screen keyboard available yet, you will need to provide Wi-Fi access using one of the following methods:
    *   **The wifi.txt method (recommended):** Before your first boot (or whenever prompted on-screen), insert the SD card into your computer. On the small partition visible to your PC, create a plain text file named `wifi.txt` containing the following lines:
        ```text
        ssid=YourNetworkName
        password=YourWifiPassword
        country=US
        ```
        *(Note: The `country` code is optional, but many 5 GHz networks require it to connect.)* Insert the card back into the Odin and power it on. Once successfully connected, the system will rename the file to `wifi.txt.imported`. If there is an issue, an error log will be generated at `wifi-import-error.txt`.
    *   **USB alternative:** Plug in a USB keyboard or dock and use a wired connection or terminal.
    
    *Please anticipate a brief wait.* The download itself is relatively small, but the setup process writes thousands of small files. The speed of this step depends entirely on your SD card - it may take a few minutes on a fast card, or up to 30-60 minutes on a slower one. The status screen will keep you updated. It is safe to interrupt this process; if powered off, it will simply resume on the next boot.
3.  **Network Setup:** Once Steam is downloaded, you will be prompted to select your Wi-Fi network (if you didn't use the `wifi.txt` method) before landing in the standard Steam setup.
4.  **Sign in to Steam.** ⚠️ Immediately after signing in, Steam will quietly download and apply an update in the background. Until this process finishes, the user interface may feel sluggish, menus might lag, and you may occasionally see a "connection problem" message while the storage drive works heavily. On slower SD cards, this can last 10-20 minutes. Please be patient and let it finish. Once the background update completes, the interface will return to its normal, responsive state.
5.  **You're ready!** You are now in Big Picture mode. Controls, sound, and rumble are configured out of the box. The thumbstick RGB rings are disabled by default; you can enable them by navigating to **Quick Access -> Decky -> Pocknix Control**.

**Additional Features:**
*   **Sleep Mode:** A short press of the power button will suspend the device (measured standby drain is under 1% per hour). 
*   **Power Management:** Fan curves and power profiles (Eco, Balanced, Performance) can be found in **Quick Access -> Decky -> Pocknix Control -> Power**. Please note that the battery charge limit setting is currently **experimental** and the device may occasionally charge past the specified limit.
*   **Frame Insertion:** The **Frame Insertion (LSFG)** toggle in **Pocknix Control -> Games** utilizes the model from **Lossless Scaling**, which is a paid application on Steam (approximately 175 MB). Holodor does not include this software. Once you purchase and install Lossless Scaling via Steam, the toggle will become functional.

---

## Part D - Optional: Install to Internal Storage

Running Holodor from the internal UFS storage is noticeably faster than running it from an SD card. The installation script will gracefully shrink your Android data partition to make room for Holodor. **Your Android installation is preserved, but it will undergo a factory reset** (apps and data will be wiped, but the OS remains fully bootable from the ABL menu). Your bootloader backup from step A.2 remains your ultimate recovery option.

1.  Boot Holodor from the SD card and ensure Wi-Fi is connected.
2.  Switch to Desktop Mode or SSH into the device *(please refer to documentation for the exact terminal path if not using SSH)*. Open a terminal and run: `sudo pocknix-install-internal`
3.  Choose how much space you would like to reserve for Android (32 GB is a sensible minimum). Type `INSTALL` when prompted. The copy process will take approximately 20-30 minutes.
4.  Power off the device, remove the SD card, and power it back on. Holodor will now boot directly from your internal storage. Keep your prepared SD card in a safe place, as it serves as a bootable rescue system. *(Note: Please verify the boot order behavior when the SD card is re-inserted).*

---

## Troubleshooting

*   **ABL menu says "SD card not inserted":** The bootloader cannot read your specific card. Try using an older or slower card. (The initial card is likely perfectly fine for standard storage, just not for booting).
*   **"ERROR: Payload not found" when setting device model:** This is caused by the same issue as above - the ABL cannot read the card where the payload is located.
*   **Stuck at Steam sign-in with a spinning QR code on first boot:** Please wait 2-3 minutes for the clock to sync and the client to update. If it persists beyond 10 minutes, hold the power button for 15 seconds to force a reboot; the subsequent attempt should run cleanly.
*   **Wi-Fi shows connected but nothing loads (yellow dot on network icon):** Simply toggle Wi-Fi off and back on in Settings. Newer software builds attempt to handle this automatically after waking from sleep.
*   **A game froze and buttons are unresponsive:** Short-press the power button to put the device to sleep, then press it again to wake it up. The menu usually recovers gracefully. This is a known issue with the in-game Steam overlay in certain titles; opening the game's internal pause menu first often prevents this.
*   **The system is completely frozen:** Hold the power button for 15 seconds to force a shutdown. The system is designed to recover cleanly on the next boot using filesystem journaling and boot fallbacks.

## Current Limitations

*   Graphically demanding AAA titles generally run at around **20-30 fps**. The GPU driver for this chipset is still in active development and improves regularly. Utilizing upscaling (FSR) and frame generation can make games feel smoother than the raw frame rate suggests. Indie, 2D, and lighter 3D titles perform flawlessly at high frame rates.
*   Games requiring kernel-level anti-cheat (such as Elden Ring's Easy Anti-Cheat) are not currently supported.
*   Suspending the device while a game is actively running may cause the controller to disconnect in-game. For the most reliable experience, exit to the main Steam menu before suspending.
*   The battery **charge limit** setting is experimental. The hardware does not always honor the software limit, and the device may occasionally charge to 100%.

---

## Appendix: Enabling SSH and Setting Passwords (For Tinkerers)

For security purposes, release images are configured similarly to a standard Steam Deck: no user passwords exist and SSH remote access is disabled by default. If you wish to enable remote access:

1.  Switch to Desktop Mode and open a terminal (Konsole).
2.  Type `passwd` to set a new password for the `deck` user (you will not be prompted for an old password).
3.  Type `sudo systemctl enable --now sshd` to start the SSH service. SSH is now active and will use password or key authentication based on your configuration. *(Tip: You can use `sudo passwd root` first if you prefer direct root SSH access, though it is generally safer to log in as the `deck` user and utilize `sudo` when needed).*
