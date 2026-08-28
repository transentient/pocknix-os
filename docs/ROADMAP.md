# Holodor — road to release (written 2026-08-28)

Cliff's requirements, verbatim: **stable, stable, stable. Sleep that works — we had
that, we need it back. Smooth wake. RGB. Headphone jacks.**

Everything below is ordered by dependency. "Ceremony" = needs Cliff's hands; everything
else is agent-autonomous. Definition-of-done criteria are listed per phase — a phase is
not done until its criteria are measured, not vibed.

---

## Phase 1 — Sleep back to 0.3%/h (this week)

The kernel-22 suspend-drain regression (≥1.6%/h, battery died in <40h from 89%; prior
kernels measured 0.07–0.3%/h) is the top blocker. The device slept clean the whole
time — the sleep state itself got expensive. Prime suspects: the ArmadaOS bundle
(1005 rsinput quiesce / 1006 UART reassembly / 0701 vol-up wakeup).

- [x] Bisect variant kernels built on fusor (22.1 = −1005, 22.2 = −1006, 22.3 = −0701;
      built overnight 08-28, stashed in `~/odin3-backups/kernel-bisect-20260828/`)
- [ ] **Ceremony (~2h, one evening):** coulomb-counter soak protocol. Per config:
      unplug → 30-min suspend (`rtcwake -m no -s 1800 && systemctl suspend`) →
      `charge_counter` µAh bookends = exact drain rate. Baseline kernel-22 first
      (also rules out config-drift explanations), then variants. Agent flashes
      kernels between runs over ssh; Cliff only plugs/unplugs.
- [ ] Convict the patch. Then EITHER drop it (if its feature survives without it)
      OR find the proper fix. **Known tension:** 1006 is also the best candidate for
      the wake-jank fix that HOLDS. If 1006 is the drain culprit we need both halves:
      check ArmadaOS's tree for follow-ups, and whether their builds pay the same
      drain (their devs admit sleep isn't fully worked out — we should not inherit
      their drain to get their wake fix).
- [ ] Steam download suspend-inhibitor (we hold none — verified 08-28; SteamOS does).
      Fixes suspends-mid-download. Small bsp unit watching for active downloads.

**Done when:** unplugged deep-sleep drain ≤0.3%/h measured over a full overnight, AND
wake-jank stays fixed (zero rsinput frame errors, controls live post-wake), AND
plugged-in overnight suspend is clean, AND suspend-mid-game still works.

## Phase 2 — Stock restore + fresh install walkthrough (weekend ceremony)

Cliff's call 08-28: flash back to stock and go through the install once more.
This is the queued EDL plan + INSTALL.md validation in one block (~2-3h).

- [ ] **EDL/QFIL full factory restore** (Cliff on BONESAW, QPST/QFIL + CN tutorial in
      the EDL package). Wipes every UFS LUN to one matching Dec-2025 build. The SD
      card is untouched — current Holodor daily driver survives in hand.
      Pre-EDL rescue: already done (08-15/16, `~/odin3-backups/`); nothing new has
      been written to internal since (device SD-boots). Re-verify before flashing.
- [ ] **THE JACK TEST on stock Android, immediately** (Cliff asked not to be allowed
      to forget). Does Android auto-detect a 3.5mm plug? This decides the jack
      end-state:
      - Android detects → real gap on our side → resume MBHC detect hunt post-release
        (vendor DTB ground truth already mined; audio itself already works).
      - Android does NOT detect → manual output switching is **platform parity** →
        ship it documented, close the hunt for good.
- [ ] Does stock Android boot fully? (Expected yes — full-LUN reflash is the best
      theory for the old post-AVB failure. If it still fails: AYN email, but not
      release-blocking; Android is a bonus on this device now.)
- [ ] OTA Android up to current, then **INSTALL.md end-to-end as a fresh user**:
      ABL flash via Run-Script-as-Root from Android, boot the validated RC from SD,
      wifi.txt import, seedless bootstrap, OOBE. Then OTA to the Phase-3 respin when
      it lands — which validates the OTA path on a virgin install too.

**Done when:** jack question answered and logged, Android state known, INSTALL.md
walked start-to-finish by a human with no agent rescue.

## Phase 3 — RC respin with everything (agent work, gated on Phase 1)

- [x] Commit the 08-28 device-side wifi fixes to the repo (RC/repo parity rule):
      iwd roam thresholds now baked by build-sd-image.sh (RoamThreshold/5G=-85,
      Critical pair=-90). `autoconnect-retries=0` was ALREADY shipped in the
      importer — the sulky device profile was a manual UI dupe that lacked it.
- [x] **Charging trap fixed (08-28 finding, user-visible badly):** battmgr firmware
      DEFAULTS to an 80%/70% battery-care window; the 70% restart never fires in
      deep suspend, so "plugged in overnight" wakes at ~60%. New
      `pocknix-charge-full` boot unit (bsp-common-14) forces 100/95 until a real
      opt-in battery-care panel exists. Applied live on device too.
      Related open: post-dead-battery fuel-gauge readings jump wildly (61%→99%
      within minutes, charge_counter leaps) — recalibration artifact family;
      distrust single capacity reads after a full discharge.
- [ ] Kernel-2x: drain fix in, wake fixes kept, rumble + vol-up-must-not-wake
      validation (still pending from kernel-22 scoreboard).
- [ ] Sulk hardening: port upstream 696119c iwd/wlan0 boot-race fix.
- [ ] Splash-hold fix (the ~22s splash→gamescope dark gap + short-press death spiral
      — priority polish, turns the scariest-looking non-bug into a non-event).
- [ ] Download-inhibitor unit (Phase 1 item) in the image.
- [ ] Respin, loop-mount spot-check (always), flash, quick validation ceremony.

## Phase 4 — RGB (small, parallel to anything)

LEDs work (HTR3212 driver + `pocknix-stick-leds`, shipped 08-09). Remaining is UX:

- [ ] RGB picker panel in Pocknix Control QAM (color + off/static/status modes —
      parity with the fan/power selectors). Agent work, plugin dist builds on fusor.
- [ ] Find the unidentified Decky control that turned LEDs off (08-20 mystery);
      make defaults deliberate: off by default, picker enables, ff6600 static fallback.
- [x] Lights-off-in-sleep hook — already shipped (bsp-common `leds-sleep-pre/post`
      stops the animator and zeroes the rings before suspend; verified 08-28).

## Phase 5 — Stability soak (the "stable, stable, stable" gate)

One week of daily-driver use on the frozen release stack. No new features enter
during the soak; only fixes for soak findings, which restart the clock on the
affected area.

**Soak pass criteria (a week with zero of):** forced power-holds, dead-controls
rescues, silent-audio boots (SoundWire race), wifi sulks (mitigation validation),
suspend wedges, overlay jams that need ssh rescue.

Known open bugs on the watch list, with rescues documented (docs/): overlay jam
(steamclient IPC family), VS controls-dead-at-launch race (quit+relaunch), SoundWire
codec enum race (reboot; probe-retry is the fix if it recurs in soak), flathub DNS
oneshot (restart clears; ordering fix queued), USBSS re-probe tripwire (watching).

## Phase 6 — Release mechanics

- [x] **License gate: RESOLVED.** pocknix-os#21 closed 2026-07-28; upstream now
      carries GPL-2.0 (LICENSE.md; maintainer also emailed Cliff). Verified via
      GitHub API 2026-08-28. Holodor's combined license = GPL-2.0 (upstream 2.0 +
      Armada 2.0-or-later + kernel patches all compose).
- [ ] Add Holodor's own LICENSE file (GPL-2.0, matching upstream — read their
      LICENSE.md text first for any or-later language) + final credits pass
      (ROCKNIX, Holo Core, ArmadaOS, batocera.pocket — tracked in README/PATCHES).
- [ ] Cliff decision: flip the repo public (can happen any time now — no longer
      coupled to anything external).
- [ ] Final image → archive.org (`holodor-odin3` identifier; metadata proposed to
      Cliff first — identifiers are permanent).
- [ ] OTA repo public flip per docs/pacman-repo.md checklist (coupled to license gate).
- [ ] Docs audit: Cliff rewrites public prose (plain language, hyphens not em-dashes,
      no jokes, conservative perf claims), agent audits accuracy.
- [ ] Website landing page refresh + announcement (Discord).

**Ship guards (never in a public image):** wifi PSK preseed, default passwords
unchanged (root/deck `pocknix` — change flow needed), seeded Steam client, telemetry
loggers, LED/test debris.

---

## Timeline sketch (Cliff-time is scarce; agent front-loads)

- **Fri 08-28 eve:** Phase 1 soak ceremony (~2h, mostly idle waiting)
- **Weekend 08-29/30:** Phase 2 block (EDL + jack test + install walkthrough)
- **Next week:** Phase 3 respin + Phase 4 RGB; Phase 5 soak starts on the respin
- **~Mid-September:** release, if the soak is clean and the license gate opens

The one watch item that could move the date: the 1006 drain/wake tension (may need
a real kernel fix, not a revert). The license gate resolved 07-28 (see Phase 6) —
nothing external blocks the release anymore.
