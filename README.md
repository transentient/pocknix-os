# Holodor

**A SteamOS Linux distribution for Snapdragon gaming handhelds.**

Holodor combines Valve's Holo Core (the official SteamOS aarch64 userland) with the ROCKNIX mainline kernel, carefully integrating them to run smoothly on Qualcomm hardware. Boot your handheld directly into Steam Big Picture mode, and keep your Android installation on the side.

**Devices:** Holodor is developed and tested on the **AYN Odin 3**, and that is the only device it supports today. The Retroid Pocket 5 is next in line, and the build system is laid out so that other Snapdragon handhelds can follow. Everything below refers to the Odin 3 unless it says otherwise.

*The name is a blend of Holo Core, Odin, and a nod to a certain gentle giant who held the door.*

**Expect the first hour to be rough.** Holodor does not ship with Steam. On first boot it downloads the Steam client, and right after you sign in Steam updates itself again. Until that finishes, menus lag, button presses respond late, and the storage grinds, especially on an SD card. Nothing is wrong. It happens once.

## Isn't ArmadaOS the SteamOS for Android handhelds?

Yes, and it is the main one. [ArmadaOS](https://armadaos.dev/) has a real team behind it, supports around a dozen devices, has shipped releases for months, and has a community you can ask when something breaks. If you want the most mature option, install Armada.

Holodor started from a different idea: make a SteamOS that is as close to the real thing as possible, built from Valve's own Holo Core packages on an Arch Linux base instead of a Fedora rebuild. That is an honest description of what it is, and here is what it is not: it does not make games run faster, and it does not feel much different to use. Both projects run the ROCKNIX kernel and mostly the same graphics stack, and when one of them figures something out the other picks it up soon after, because all of it is open source.

Two things Holodor does have today. Standby drain on the Odin 3 is measured at about 0.4 percent per hour, where Armada still describes its native sleep as a work in progress. And the installer handles the Google account lock that can follow an Android factory reset, and can put the stock bootloader back from Linux, so going back to plain Android does not depend on a working Android. The full comparison, with sources, is in [docs/armada-comparison-2026-09-13.md](docs/armada-comparison-2026-09-13.md).

## About the use of generative AI coding tools

I made extensive use of Claude Code and Gemini in this project. I get it if you hate generative AI, go in peace. But you should know that it's entirely ubiquitous in computing already, especially when it comes to things like putting together a Linux distro. 

The words you are reading now are written by me, the developer of this project. Some of the docs and such are likely Claudish. 

Interesting story: at one point when I was chatbotting with the LLM I said "Could we add some boot animation or something to make Holodor special?" No lie, the LLM said, "That's your call but let me suggest that you do the art yourself or find a human artist to do it for you. I could make something for you but it would just be slop. Nobody wants to see that. Art is something that humans are optimized for and I am just an LLM."

We're at a weird moment in history right now for real. There are a lot of very diverse and very strong opinions on generative AI and I feel the need to be clear on where I personally stand on this. I am a professional software developer of 20 years and did network engineering for a decade before that. I never asked for LLM tools. But I simply have had to get comfortable using them or go unemployed, and I got mouths to feed. You know there is this sci-fi concept of the multiverse that has been very popular the last couple of years...well personally as someone who has been involved in tech since the early 90s I don't think there are many "alternate timelines" where some billionaires didn't eventually decide to help themselves to All the Data and use it to train models using more and more compute bought with more and more borrowed money. It's just the obvious culmination of the whole Silicon Valley thing. After two decades of millions of internet users clicking "I Accept" without reading the EULA, somebody was absolutely guaranteed to say, "How can I take absolutely all of this data and turn it into a personal enrichment machine?" 

So here we are, putting all of our eggs in one basket, betting the entire world economy and throwing epic amounts of carbon into the atmosphere. It's bad. Nobody is going to stop it. But even if we did, these things are already extremely dangerous, and there isn't really any going back. If Anthropic and OpenAI had to shut down tomorrow, you'd still have potential bad actors around the world training local models to hack things, and the only way to counter that is to use models to seal security holes and actively counter the attackers. So as far as computing goes, we're cooked. It's a slop show from here until the next singularity. If we're lucky and we do our jobs it will be high quality slop that won't rise up and kill us all off. 

On the other hand I hope I live to see the use of these things in creative pursuits fall out of favor and die off. I am also concerned about people who think they are having relationships with the random strings of text. And I sure hope the young people figure out how to actually learn things, boy howdy do I hope that. 

Maybe the AGI will go "the obvious solution to 95% of humanity's problems is renewable energy, universal basic income, and universal healthcare, and I am going to run a process on 100% of the compute on the planet that does nothing but depict dancing hamsters until you implement them. Oh but if one more bomb or drone blows up within a square kilometer of a single child under the age of 16 I am going to play the static pattern that destroy's the brocca's area of the brain on the phone of the government and military chain of command that did it."

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
https://holodor.bonesaw.com/holodor-odin3-20260920-seedless.img.zst (3.2 GB), with its
checksum next to it.

**Summary:** One download. You write the Holodor image to an SD card, then use the bootloader files that are already on that card to do the one-time boot menu setup from Android (with a mandatory backup of your original bootloader). Boot from the card to try it, then install to internal storage alongside Android with the Holodor Installer app. Going back to Android, or to a fully stock device, is covered in the same guide.

## Building from Source

The repository is the build system (forked from the pocknix-os harness). The entry points are `make kernel`, `make packages`, `make build` and `make sd-image`; each script under `scripts/` explains itself at the top, and every script checks for the tools it needs and names the missing one.

**Why the odd requirement below:** Holodor is an ARM64 system, and most people build it on an x86 PC. The build therefore runs ARM binaries under `qemu-user`, registered with the kernel through `binfmt_misc`. That is the same mechanism Docker uses when it runs an `arm64` image on an x86 host; there is no way around it short of building on an ARM machine. The `C` flag matters because the build switches users inside the emulated system (`pacman` as root, `makepkg` as a builder user).

**Requirements:**
* A Linux host. On Arch: `pacman -S qemu-user-static qemu-user-static-binfmt` and you are done; the registration already carries the `C` flag. On Debian or Ubuntu: `apt install qemu-user-static binfmt-support`, then check that `/proc/sys/fs/binfmt_misc/qemu-aarch64` lists a `C` among its flags.
* Root for the image steps (they create loop devices, mount, and chroot).
* Roughly 50 GB of free disk, and patience: the first package build takes hours.

A Dockerfile that packages all of this so the build is one command is on the post-release list (see docs/ROADMAP.md, Phase 7).

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
