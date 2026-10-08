# Odin 3 game results (kernel 7.1.3-33, steam 49, 120 Hz panel, frame limit 60 unless noted) — 2026-10-08
| Game | Engine/API | Scene | fps | ms p50/p95/p99 | visible p95/p99 | notes |
|---|---|---|---|---|---|---|
| Celeste | 2D (FNA, Windows build) | prologue | 60.0 | 16.7/17.7/18.3 | 23.8/31.9 | flat; visible-frame jitter = 60 fps on a 120 Hz panel (1x:14% 2x:58% 3x:25%) |
| Stardew Valley | 2D (XNA, Windows build) | menu | 60.0 | 16.7/17.1/17.6 | | mouse-driven menus |
| Balatro | 2D (LÖVE) | unlock screen | 118.6 | 8.4/8.6/8.7 | | runs at the panel's 120 Hz, no cap applied; A button ignored on that screen |
| Outer Wilds | Unity, DX11 | village, start of loop (max quality, as shipped) | 21.0 | 47.1/49.5/49.7 | 94.8/98.2 | GPU 1.1 GHz, 86 C; main thread 48 %; RP5 was 10 at the same settings. Wake Up prompt ignores single presses; a burst of 6 X presses took. |
| Hollow Knight | Unity 2D, DX11 | King's Pass (start) | 118.7 | 8.4/9.5/11.4 | 8.4/8.4 | GPU pinned at 1.1 GHz for a 2D game, 75 C; intro video PLAYS (with proton-medialibs 3); menu 118.7 at 120 Hz |
| Portal | Source, DX9 | test chamber 00 | 65 (uneven) | 13.1/20.6/20.7 | 20.9/21.4 | bimodal 13 / 20.6 ms frames, 30 % over 1.5x median; GPU 1.1 GHz, 77 C; menu 76 |
| Risk of Rain 2 | Unity, DX11 | character select (defaults) | 45.5 | 22.0/22.1/22.1 | 22.1/22.2 | GPU 1.1 GHz, 77 C; RP5 was 18 here; Ready (X) press not taken |
| Observer | UE4, DX11 | main menu | 22.7 | 43.8/45.2/45.6 | | CRASH ROOT CAUSE LEAD: UE4 `HttpManagerThread` raises an exception with a frame outside its stack ("Exception frame is not in stack limits => unable to dispatch exception", Wine seh) about 2 min in, menu or intro; adding `[HTTP] bEnableHttp=false` to Saved/Config/WindowsNoEditor/Engine.ini kept it alive 5+ min at the menu. In-game not yet verified. Launcher needs a touch on PLAY. |
| Vampire Survivors | 2D (Phaser/Electron -> native) | run start (arcana screen + stage) | 118.8 | 8.5/9.7/11.6 | 8.4/8.4 | 120 Hz, 1x refresh 100 %; GPU 1.05 GHz, 77 C. Reference game. |
| DOOM (2016) | id Tech 6, Vulkan (`+r_renderAPI 1`) | The UAC, first room, standing | 19.0 | 48.7/78.1/87.4 | 73.8/90.0 | main thread "Zion" 97 % = CPU-bound under FEX; GPU 1.05 GHz, 84 C. Default OpenGL renderer: ~1 fps at the menu, unusable; Vulkan menu 31.7. Launch option required. |
| Dark Souls Remastered | DX11 | Undead Asylum cell, standing | 60.0 | 16.6/18.5/19.1 | 28.1/28.8 | flat 60 (game cap); the 60-on-120 Hz pacing again (visible 2x:55 % 1x:16 % 3x:19 %). dxvk-frame 42 %, game 32 %; GPU 1.1 GHz, 77 C. First launch ~2.5 min to the title. RP5: 28. |
| Deep Rock Galactic | UE4, DX11 (Steam's first launch option) | tutorial drop pod, descending | 38.7 | 25.9/26.2/26.3 | 26.2/26.3 | vsync-snapped to every 3rd refresh (3x: 99 %); hottest zone 96 C; GPU 1.1 GHz. RP5: 14 on the space rig. |
| The Talos Principle | Serious Engine, DX11 (DXVK) | attract scene | 66.0 | 15.2/15.5/15.6 | 23.6/23.8 | flat; GPU 900 MHz, 64 C. "Press any key" ignored the gamepad; keyboard Enter opened a Croteam login prompt. RP5: 57 with hitches. |
| Hades | 2D, DX11 (Steam's first launch option) | Tartarus, first chamber (loaded save) | 118.8 | 8.4/8.5/8.6 | 8.4/8.4 | GPU 1.1 GHz, 83 C; menu 118.8 at 120 Hz. RP5: 58 at 60 Hz. |
