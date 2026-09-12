# Holodor

**A streamlined, SteamOS-compatible Linux distribution for the AYN Odin 3.** 

Holodor combines Valve's Holo Core (the official SteamOS aarch64 userland) with the ROCKNIX mainline kernel, carefully integrating them to run smoothly on Qualcomm hardware. This allows you to boot your Odin 3 directly into Steam Big Picture mode while preserving your Android installation on the side.

*The name is a blend of Holo Core, Odin, and a nod to a certain gentle giant who held the door.*

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
| Battery charge limit setting | Experimental — the device may still charge to 100% |
| Auto storage expansion, sleep/wake telemetry | ✅ Supported |
| Optional install to internal UFS | ✅ Supported (Preserves Android; requires a factory reset) |

## Current Limitations

- Graphically intensive AAA titles typically run at **20-30 fps**. The GPU driver for this chip is still in early development and sees regular improvements. Upscaling (FSR) and frame generation can make gameplay feel noticeably smoother than the raw frame rate suggests. Indie, 2D, and lighter 3D titles run flawlessly at high frame rates.
- Games requiring kernel-level anti-cheat (such as EAC or BattlEye) are currently unsupported. This is a known challenge across the broader ARM ecosystem that Valve is actively working to address.
- The in-game Steam overlay may exhibit graphical glitches in some heavier titles. A workaround is included, and a permanent fix is currently in progress. 
- The headphone jack outputs audio correctly, but automatic detection is not yet functional. You will need to manually switch the audio output when plugging in headphones.

## Installation

Please refer to **[INSTALL.md](INSTALL.md)** for detailed instructions. 

**Summary:** You will perform a one-time ROCKNIX bootloader setup (which includes a mandatory backup), flash the image to a compatible SD card, and boot the device. You may optionally install Holodor to your internal storage afterward.

## Building from Source

The repository serves as the build system (forked from the pocknix-os harness). You will find `scripts/build-kernel.sh`, `build-packages.sh`, `build-image.sh`, and `build-sd-image.sh`, all of which are documented inline. 

**Requirements:** 
* A Linux host with `qemu-user binfmt` enabled (including the `C` flag — please see the `docs/` directory for details).
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
