# Holodor

**A SteamOS-faithful Linux for the AYN Odin 3.** Valve's Holo Core (the official
SteamOS aarch64 userland) + the ROCKNIX mainline kernel + the glue to make them love
a Qualcomm handheld. Boot your Odin 3 into Steam Big Picture; keep Android on the
side.

*The name: Holo Core + Odin + a certain gentle giant who held the door.*

## What works (hardware-verified, receipts in the commit log)

| | Status |
|---|---|
| Steam Big Picture (native ARM64 client) | ✅ boots straight in |
| x86/x86-64 Windows games (FEX + Proton + DXVK/vkd3d) | ✅ |
| Controls (buttons, sticks, paddles, deadzones) | ✅ correct out of the box |
| **Rumble / haptics** | ✅ in-game |
| **Thumbstick RGB** | ✅ (`pocknix-stick-leds`, and yes it glows) |
| Audio (speakers) | ✅ |
| Wi-Fi (with post-sleep self-healing) | ✅ |
| **Suspend/resume** | ✅ works from anywhere, including inside a running game; under 0.5%/hr measured standby drain |
| Power profiles (Eco/Balanced/Performance) + fan curves | ✅ in Quick Access |
| Battery charge limit setting | experimental - the device may charge to 100% anyway |
| Auto storage expansion, sleep/wake telemetry | ✅ |
| Optional install to internal UFS (Android preserved, factory-reset) | ✅ |

## Honest limitations

- Heavy AAA titles currently run around **20-30 fps** - the GPU driver for this
  chip is young and improving month to month. Upscaling (FSR) and frame
  generation can make games feel noticeably smoother than the raw number
  suggests. Indie/2D/light-3D titles run flawlessly at high framerates.
- Kernel anti-cheat titles (EAC/BattlEye) don't run yet - an ecosystem-wide ARM
  frontier that Valve's Steam Frame work is actively pushing.
- In-game Steam overlay is glitchy in some heavy titles (workaround inside; fix in
  progress). Headphone jack: audio plays through it, but plugging headphones in is
  not detected automatically, so the output has to be switched by hand.

## Install

See **[INSTALL.md](INSTALL.md)**. Summary: one-time ROCKNIX bootloader setup (with
mandatory backup), flash the image to a compatible SD card, boot; optionally install
to internal storage afterward.

## Building from source

The repo is the build system (a fork of the pocknix-os harness): `scripts/build-kernel.sh`,
`build-packages.sh`, `build-image.sh`, `build-sd-image.sh`, each documented inline.
You'll want a Linux host with qemu-user binfmt (with the `C` flag - see
`docs/`), ~50 GB free, and patience for the first package build.

## Credits

Holodor stands on extraordinary shoulders:

- **[ROCKNIX](https://github.com/ROCKNIX)** - the SM8750 kernel bring-up, device
  trees, firmware curation, and the bootloader path. The foundation.
- **[Valve](https://store.steampowered.com) & [Collabora](https://www.collabora.com)** -
  Holo Core, the official SteamOS aarch64 userland this project is faithful *to*.
- **[ArmadaOS](https://github.com/armada-os)** - pioneering SteamOS-on-Odin, the
  haptics bring-up we ported, hard-won suspend fixes, and the design of the fan
  curve editor.
- **[batocera.pocket](https://github.com/darkplace/batocera.pocket)** (lukemotion,
  continuing suckbluefrog's work) - the stick-LED driver, Wi-Fi resilience ideas,
  and more.
- **[shuuri-labs/pocknix-os](https://github.com/shuuri-labs/pocknix-os)** - the
  build harness this repo forks.
- **Teguh Sobirin** - the Odin 3 audio UCM.
- The **FEX-Emu**, **Mesa/Turnip**, and **InputPlumber** projects.
- The AYN Odin 3 Linux community on Discord - intel, testing, and honest complaints.

## License

GPL-2.0 (see [LICENSE](LICENSE)), the same license as the projects above. Art assets by
**ssalmon** (CC-BY 4.0).

*Not affiliated with Valve, AYN, or anyone else. Steam is a trademark of Valve Corp.
This project will factory-reset Android if you install internally, and while every
step is designed to be reversible, you flash at your own risk.*
