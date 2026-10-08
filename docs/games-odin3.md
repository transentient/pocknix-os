# Games tested on the AYN Odin 3

Measured on Holodor with the frame-timing tools in `tools/rp5-bench` (they work on both devices), screen at 1080p. "fps" is the average over 30 to 45 seconds of the scene named. All games ran through Proton (the ARM Steam client cannot run native Linux x86 games; see notes). Kernel 7.1.3-33, the shipped one. Device plugged in, battery full.

The Odin 3's screen is 120 Hz. In this pass the 60 fps frame limit was not limiting (see notes), so 2D games ran at 120 fps with the GPU at full clock. The Retroid Pocket 5 numbers are in [games-rp5.md](games-rp5.md); the same scene was used wherever it could be reached.

| Game | Engine / API | Scene | fps | Notes |
|---|---|---|---|---|
| Vampire Survivors | 2D | run start | 120, flat | Reference game. RP5: 60. |
| Hades | 2D, DX11 | Tartarus, first chamber | 120, flat | RP5: 58. |
| Hollow Knight | Unity 2D, DX11 | King's Pass | 120, flat | Intro video plays. RP5: 52, no intro. |
| Celeste | 2D, Vulkan | prologue | 60, flat | Game's own 60 cap; on the 120 Hz panel frames show for 1, 2 or 3 refreshes (slight judder). |
| Stardew Valley | 2D | menu | 60, flat | Game's own cap. |
| Balatro | 2D | unlock screen | 120, flat | |
| Dark Souls Remastered | DX11 | Undead Asylum, standing | 60, flat | Game's own cap. About 2.5 minutes to the title on first launch. RP5: 28. |
| The Talos Principle | Serious Engine, DX11 | attract scene | 66, flat | RP5: 57 with hitches. |
| Portal | Source, DX9 | test chamber 00 | 65, uneven | Frames alternate 13 and 21 ms. |
| Risk of Rain 2 | Unity, DX11 | character select | 46, flat | RP5: 18. |
| Deep Rock Galactic | UE4, DX11 | tutorial drop pod | 39, flat | CPU cores reached 100 C, fan at maximum. RP5: 14. |
| Observer | UE4, DX11 | main menu | 23 | Crashes about 2 minutes in (same as the RP5); see notes for the fix being tested. |
| Outer Wilds | Unity, DX11 | village, start of loop | 21, flat | Game at its maximum quality preset (default). RP5: 10. |
| DOOM (2016) | id Tech 6 | The UAC, first room | 19 | Needs `+r_renderAPI 1` in launch options (Vulkan); the default OpenGL renderer runs at about 1 fps. CPU-bound. |
| Death Stranding | Decima, DX12 | | playable | From the 20261002 release notes; rumble works. Not yet re-measured. |
| Clair Obscur: Expedition 33 | UE5 | | runs with `-dx11`, not playable | From the 20261002 release notes. |

Notes:
- The 60 fps frame limit was not applied by the gamescope build in the 20261002 image (games ran at 120). The gamescope with the refresh-rate fix from the Retroid Pocket 5 build is going into the next Odin 3 image; the numbers above will be re-measured with it.
- Observer: the crash is Unreal's HTTP thread raising an exception Wine cannot deliver. Adding `[HTTP]` / `bEnableHttp=false` to the game's `Engine.ini` kept it running in testing; a per-game fix is being prepared.
- DOOM (2016): set `+r_renderAPI 1` in the game's launch options before the first start.
- Unreal Engine 5 games need `-dx11` in their launch options.
- Native Linux games: the ARM Steam client has no Linux runtime, so every x86 game runs through Proton.
- Heavy 3D games push the CPU cores to 100 C within minutes with the fan at maximum; expect throttling in long sessions.
