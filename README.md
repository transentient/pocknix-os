# Holodor

**A SteamOS Linux distro for Snapdragon handhelds.**

Holodor takes Valve's Holo Core (the official ARM64 SteamOS userland) and mashes it up with the ROCKNIX mainline kernel so it actually runs on Qualcomm chips. It boots straight into Steam Big Picture, leaving your Android partition intact.

Right now, it's only built and tested for the **AYN Odin 3**. The Retroid Pocket 5 is on the radar, and the build system is set up to add more Snapdragon devices later. Assume everything below is about the Odin 3.

*The name: Holo Core + Odin + that one big guy who held the door.*

**The first hour is going to be janky.** Holodor doesn't pack the Steam client in the image. On the very first boot, it downloads Steam, and as soon as you log in, Steam immediately updates itself again. While that's happening, menus will lag, button inputs will feel ignored, and your storage will grind (especially if you're running off an SD card). Don't panic. It only does this once.

## Isn't ArmadaOS like, **THE** SteamOS for Odin 3 and other android handhelds?

Yeah, [ArmadaOS](https://armadaos.dev/) is great. They have a solid team, support a bunch of devices, and have been shipping for months. If you want the most stable, mature option, go install Armada.

Holodor exists because I wanted to see how close I could get to the real SteamOS, using Valve's actual Holo Core packages on an Arch Linux base instead of rebuilding on Fedora. Honestly? The end user experience isn't massively different. Holodor isn't magically faster. Both use the ROCKNIX kernel and a similar graphics stack. When one project fixes a bug, the other usually ports it over. Open source at work.

We might have better sleep battery drain than ArmadaOS right now. We did a couple weeks ago, anyway. Things move fast. I had to bash my head against the wall to fix Android dual-booting and a full factory restore, so we have those sorted out now. You can read the full breakdown in [docs/armada-comparison-2026-09-13.md](docs/armada-comparison-2026-09-13.md).

## About the use of generative AI coding tools

I made extensive use of Claude Code and Gemini in this project. I get it if you hate generative AI, go in peace. But you should know that it's entirely ubiquitous in computing already, especially when it comes to things like putting together a Linux distro. 

The words you are reading now are written by me, the developer of this project. Some of the docs and such are likely Claudish. 

Interesting story: at one point when I was chatbotting with the LLM I said "Could we add some boot animation or something to make Holodor special?" No lie, the LLM replied, "That's your call but let me suggest that you do the art yourself or find a human artist to do it for you. I could make something for you but it would just be slop. Nobody wants to see that. Art is something that humans are optimized for and I am just an LLM." (So I reached out on reddit and connected with the talented and honest SSalmon, who for a very reasonable price graced us with some cool bootup art and animation.) 

We're at a weird moment in history right now for real. There are a lot of very diverse and very strong opinions on generative AI and I feel the need to be clear on where I personally stand on this. I am a professional software developer of 20 years and did network engineering for a decade before that. I never asked for LLM tools. But I simply have had to get comfortable using them or go unemployed, and I got mouths to feed. You know there is this sci-fi concept of the multiverse that has been very popular the last couple of years...well personally as someone who has been involved in tech since the early 90s I don't think there are many "alternate timelines" where some billionaires didn't eventually decide to help themselves to All the Data and use it to train models using more and more compute bought with more and more borrowed money. It's just the obvious culmination of the whole Silicon Valley thing. After two decades of millions of internet users clicking "I Accept" without reading the EULA, somebody was absolutely guaranteed to say, "How can I take absolutely all of this data and turn it into a personal enrichment machine?" 

So here we are, putting all of our eggs in one basket, betting the entire world economy and throwing epic amounts of carbon into the atmosphere. It's bad. Nobody is going to stop it. But even if we did, these things are already extremely dangerous, and there isn't really any going back. If Anthropic and OpenAI had to shut down tomorrow, you'd still have potential bad actors around the world training local models to hack things, and the only way to counter that is to use models to seal security holes and actively counter the attackers. So as far as computing goes, we're cooked. It's a slop show from here until the next singularity. If we're lucky and we do our jobs it will be high quality slop that won't rise up and kill us all off. 

On the other hand I hope I live to see the use of these things in creative pursuits fall out of favor and die off. I am also concerned about people who think they are having relationships with the random strings of text. And I sure hope the young people figure out how to actually learn things, boy howdy do I hope that. 

Maybe the AGI will go "the obvious solution to 95% of humanity's problems is renewable energy, universal basic income, and universal healthcare, and I am going to run a process on 100% of the compute on the planet that does nothing but depict dancing hamsters until you implement them. Oh but if one more bomb or drone blows up within a square kilometer of a single child under the age of 16 I am going to play the static pattern that destroy's the brocca's area of the brain on the phone of the government and military chain of command that did it."

## What Works

| Feature | Status |
|---|---|
| Steam Big Picture (native ARM64 client) | ✅ Boots directly |
| x86/x86-64 Windows games (FEX + Proton + DXVK/vkd3d) | ✅ Supported |
| Controls (buttons, sticks, paddles, deadzones) | ✅ Configured out of the box |
| **Rumble / haptics** | ✅ Functional in-game |
| **Thumbstick RGB** | ✅ Functional (`pocknix-stick-leds`) |
| Audio (speakers) | ✅ Supported |
| Wi-Fi (with post-sleep self-healing) | ✅ Supported |
| **Suspend/resume** | ✅ Works reliably, even in-game; standby drain under 0.5%/hr |
| Power profiles (Eco/Balanced/Performance) & fan curves | ✅ Available in Quick Access |
| Battery charge limit setting | Experimental - might still charge to 100% |
| Auto storage expansion, sleep/wake telemetry | ✅ Supported |
| Optional install to internal UFS | ✅ Supported (Keeps Android, but factory resets it once) |

## Current Limitations

- Heavy AAA games run around **20-30 fps**. The Snapdragon GPU driver is still young. FSR and frame generation help smooth it out a lot, but don't expect miracles. Indie and 2D games run flawlessly.
- Kernel-level anti-cheat (EAC, BattlEye) doesn't work. This is an ARM-wide problem that Valve is still figuring out.
- The Steam overlay glitches out in some heavier games. There's a workaround included; working on a real fix.
- The headphone jack works, but it doesn't auto-detect when you plug something in. You have to switch the audio output manually.

## Installation

Read **[INSTALL.md](INSTALL.md)** for the step-by-step guide. The latest image is here: `https://holodor.bonesaw.com/holodor-odin3-20260920b-seedless.img.zst` (3.2 GB) (checksum is next to it).

**TL;DR:** Grab the image and the ROCKNIX bootloader. Flash them to an SD card, use the new bootloader to set up the boot menu from Android (back up your stock bootloader when it tells you to!). Boot from the SD card to test it out. If you like it, use the Holodor Installer app to flash it to your internal storage alongside Android. The guide also covers how to revert back to stock.

## Building from Source

The repo is the build system (forked from `pocknix-os`). Run `make kernel`, `make packages`, `make build`, and `make sd-image`. The scripts in `scripts/` are documented at the top and will yell at you if you're missing dependencies.

**Why the weird requirement below:** Holodor is an ARM64 OS, but you're probably building it on an x86 PC. It uses `qemu-user` registered via `binfmt_misc` to run ARM binaries during the build (same way Docker runs arm64 containers). You need the `C` flag enabled because the build switches users (running `pacman` as root and `makepkg` as a standard user).

**Prerequisites:**
* A Linux machine. Arch users: `pacman -S qemu-user-static qemu-user-static-binfmt` (this sets the `C` flag automatically). Ubuntu/Debian users: `apt install qemu-user-static binfmt-support`, then verify `/proc/sys/fs/binfmt_misc/qemu-aarch64` shows a `C` flag.
* Root access (the scripts mount loop devices and chroot).
* ~50 GB of free space and a lot of patience. The initial package build takes hours.

*(A Dockerfile to make this a one-click build is planned for Phase 7 in `docs/ROADMAP.md`).*

## Credits

This project stands on the shoulders of giants. Thanks to:

- **[ROCKNIX](https://github.com/ROCKNIX)**: The SM8750 kernel bring-up, device trees, and bootloader.
- **[Valve](https://store.steampowered.com) & [Collabora](https://www.collabora.com)**: For Holo Core itself.
- **[ArmadaOS](https://github.com/armada-os)**: The original Odin SteamOS pioneers. We use their haptics work, suspend fixes, and fan curve editor.
- **[batocera.pocket](https://github.com/darkplace/batocera.pocket)** (lukemotion/suckbluefrog): The stick-LED driver and Wi-Fi fixes.
- **[shuuri-labs/pocknix-os](https://github.com/shuuri-labs/pocknix-os)**: The build harness this repo is forked from.
- **Teguh Sobirin**: Odin 3 audio UCM.
- The devs behind **FEX-Emu**, **Mesa/Turnip**, and **InputPlumber**.
- The AYN Odin 3 Linux Discord community for testing and bug reports.
- AYN Technologies for building a solid handheld with a great ARM chip, even if we are squishing their firmware into a tiny partition.

## License

GPL-2.0 (see [LICENSE](LICENSE)). Same as the upstream projects. Boot art by **ssalmon** (CC-BY 4.0).

*Disclaimer: Not affiliated with Valve or AYN. Steam is Valve's trademark. Installing to internal storage will factory-reset your Android partition. Flash at your own risk.*
