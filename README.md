# Holodor

**A SteamOS Linux distribution for Snapdragon gaming handhelds.**

Holodor combines Valve's Holo Core (the official SteamOS aarch64 userland) with the ROCKNIX mainline kernel, carefully integrating them to run smoothly on Qualcomm hardware. Boot your handheld directly into Steam Big Picture mode, and keep your Android installation on the side.

**Devices:** Holodor is developed and tested on the **AYN Odin 3**, and that is the only device it supports today. The Retroid Pocket 5 is next in line, and the build system is laid out so that other Snapdragon handhelds can follow. Everything below refers to the Odin 3 unless it says otherwise.

*The name is a blend of Holo Core, Odin, and a nod to a certain gentle giant who held the door.*

## Holodor and ArmadaOS

[ArmadaOS](https://armadaos.dev/) is the established SteamOS-style Linux for Snapdragon handhelds. It supports around a dozen devices, ships a new build most weeks, has more than a dozen contributors and a Discord community in the thousands, and includes things Holodor does not: an in-game store for emulators and plugins, Waydroid, Distrobox, experimental HDR, and dual-screen support. If you want the most tested option with people to ask, install Armada.

Holodor is a one-device, one-maintainer project. It differs in a few specific ways. The base system is Valve's Holo Core, the official SteamOS ARM userland, rather than a Fedora rebuild. Updates are plain signed pacman packages. Standby drain on the Odin 3 is measured at about 0.4 percent per hour. The installer handles the Google account lock that can follow a factory reset, and can restore the stock bootloader from Linux. Both projects build on ROCKNIX and share most of the graphics stack, so expect them to converge over time.

The full comparison, with sources, is in [docs/armada-comparison-2026-09-13.md](docs/armada-comparison-2026-09-13.md).

## About the use of generative AI coding tools

<!-- Cliff writes this section. -->

## Supported Features (Hardware-Verified)

| Feature | Status |
|---|---|
| Steam Big Picture (native ARM64 client) | ✅ Boots directly |
| x86/x86-64 Windows games (FEX + Proton + DXVK/vkd3d) | ✅ Supported |
| Controls (buttons, sticks, paddles, deadzones) | ✅ Configured out of the box |
| **Rumble / haptics** | ✅ Functional in-game |
| **Thumbstick RGB** | ✅ Functional (`pocknix-stick-leds`) |
| Audio (speakers) | ✅ Supported |
| Wi-Fi (with post-sleep self-healing) | ✅ Supported |
| **Suspend/resume** | ✅ Works reliably, even during gameplay; standby drain measured at under 0.5%/hr |
| Power profiles (Eco/Balanced/Performance) & fan curves | ✅ Available in Quick Access |
| Battery charge limit setting | Experimental - the device may still charge to 100% |
| Auto storage expansion, sleep/wake telemetry | ✅ Supported |
| Optional install to internal UFS, dual boot with Android | ✅ Supported (Android is kept but factory reset once) |

## Current Limitations

- Graphically intensive AAA titles typically run at **20-30 fps**. The GPU driver for this chip is still in early development and sees regular improvements. Upscaling (FSR) and frame generation can make gameplay feel noticeably smoother than the raw frame rate suggests. Indie, 2D, and lighter 3D titles run flawlessly at high frame rates.
- Games requiring kernel-level anti-cheat (such as EAC or BattlEye) are currently unsupported. This is a known challenge across the broader ARM ecosystem that Valve is actively working to address.
- The in-game Steam overlay may exhibit graphical glitches in some heavier titles. A workaround is included, and a permanent fix is currently in progress.
- The headphone jack outputs audio correctly, but automatic detection is not yet functional. You will need to manually switch the audio output when plugging in headphones.

## Installation

Please refer to **[INSTALL.md](INSTALL.md)** for detailed instructions. The current image is
https://holodor.bonesaw.com/holodor-odin3-20260913-seedless.img.zst (3.2 GB), with its
checksum next to it.

**Summary:** One download. You write the Holodor image to an SD card, then use the bootloader files that are already on that card to do the one-time boot menu setup from Android (with a mandatory backup of your original bootloader). Boot from the card to try it, then install to internal storage alongside Android with the Holodor Installer app. Going back to Android, or to a fully stock device, is covered in the same guide.

## Building from Source

The repository serves as the build system (forked from the pocknix-os harness). You will find `scripts/build-kernel.sh`, `build-packages.sh`, `build-image.sh`, and `build-sd-image.sh`, all of which are documented inline.

**Requirements:**
* A Linux host with `qemu-user binfmt` enabled (including the `C` flag - please see the `docs/` directory for details).
* Approximately 50 GB of free storage space.
* Please note that the initial package build may take a significant amount of time.

## Credits

Holodor was made possible thanks to the foundational work of several outstanding projects and individuals:

- **[ROCKNIX](https://github.com/ROCKNIX)** - For the SM8750 kernel bring-up, device trees, firmware curation, and the bootloader path.
- **[Valve](https://store.steampowered.com) & [Collabora](https://www.collabora.com)** - For Holo Core, the official SteamOS aarch64 userland that this project builds upon.
- **[ArmadaOS](https://github.com/armada-os)** - For pioneering SteamOS-on-Odin, the haptics bring-up, suspend fixes, and the fan curve editor design.
- **[batocera.pocket](https://github.com/darkplace/batocera.pocket)** (lukemotion, continuing suckbluefrog's work) - For the stick-LED driver and Wi-Fi resilience strategies.
- **[shuuri-labs/pocknix-os](https://github.com/shuuri-labs/pocknix-os)** - For the original build harness this repository forks.
- **Teguh Sobirin** - For the Odin 3 audio UCM.
- The teams behind **FEX-Emu**, **Mesa/Turnip**, and **InputPlumber**.
- The AYN Odin 3 Linux community on Discord for their testing, insights, and helpful feedback.

## License

This project is licensed under GPL-2.0 (see [LICENSE](LICENSE)), matching the licenses of the foundational projects listed above. Art assets by **ssalmon** are licensed under CC-BY 4.0.

*Disclaimer: This project is not affiliated with Valve, AYN, or any other corporation. Steam is a registered trademark of Valve Corporation. Installing to internal storage will factory-reset your Android partition. While all steps are designed to be reversible, please proceed at your own risk.*
