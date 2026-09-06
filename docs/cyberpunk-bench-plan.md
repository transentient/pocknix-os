# Cyberpunk 2077 fps — bench plan & lever analysis (2026-08-15)

## RESULTS — mesa-next-6 / fex-rootfs-4 A/B, 2026-09-06 (hands-free harness, tools/ab/)
Same 720p / Low / ResolutionScaling Off / VSync Off / FG Off ladder as runs G–J; power `max`, fan
`performance`; kernel-25, bsp-common-18, Cyberpunk 2.31 fresh install on internal UFS; built-in
benchmark, numbers read off the results screen; GPU faults 0 on both sides.

| Side | Stack | Runs (avg fps) | Mean | min / max (typ.) |
|---|---|---|---|---|
| A | mesa-next-5 + vulkan-freedreno-next-5 + fex-rootfs-3 (x86 turnip 26.1.5) | 22.16, 22.12, 22.04 | **22.11** | 16.5 / 32.7 |
| B | mesa-next-6 + vulkan-freedreno-next-6 + fex-rootfs-4 (main @ 8e12d6000b + a830 patches), fresh boot | 21.38, 21.30, 21.39 | **21.36** | 16.3 / 31.6 |
| A′ | A again, fresh boot (control for the reboot between A and B) | 21.99, 22.09, 22.09 | **22.06** | 16.4 / 32.8 |

**Verdict: B is −3.2 % (well outside the ±0.06 run-to-run spread). NOT shipped; device rolled back to
A; RC 20260906c already carries A.** The August "26.3.0-dev +4.6 %" (run I) does not transfer to this
pin. Note what the game actually loads: `/proc/<pid>/map_files` of Cyberpunk2077.exe carries the ARM
stamp (`pocknix2.5` / `pocknix2.6`), i.e. the host turnip via the FEX Vulkan thunk (fex-emu f16e268),
not the x86 payload — so the x86 turnip rebuild in fex-rootfs-4 was not what moved the number; the
ARM mesa-next pin was. Three invalid "B" runs (19:29–19:36) were on the un-quit A process and are
discarded (they equal A to 0.1 fps — a useful null result for the harness).

## RESULTS — bench session 2026-08-16 (all 720p/Low, built-in benchmark, on-device sampler verified GPU@1100 for every run)
| Run | Driver | Config | FSR/FG state (verified how) | fps |
|-----|--------|--------|------------------------------|-----|
| A | 26.1.5 | performance, fan moderate | FSR3.1+game-FG **on** (found post-hoc in UserSettings.json) | 32.35 |
| B | 26.1.5 | max, fan max | same, on | 32.28 |
| E | 26.1.5 | max + scx_lavd, fan max | same, on | 32.42 |
| G | 26.1.5 | max, fan max | **native** (file verified pre-run) | **20.87** |
| H | 26.1.5 | max + lsfg 2x env | native + lsfg injected | 20.80 (benchmark counter is blind to lsfg frames) |
| I | **26.3.0-dev** | max, fan max | **native** (file + /proc env verified pre-run) | **21.84** |
| J | 26.3.0-dev | max, fan max | **native + VSync verifiably Off** (file verified post-apply; settings=the 42fps custom set minus FSR/FG, so not identical to G/I's Low ladder) | **22.98** (repeat 23.01) |
| K | 26.3.0-dev | max, fan max | **FSR3 Performance upscale, FG off** (file verified; ~640×360 internal) | **31.91** |

**Conclusions (measured, not theorized):**
- Native ceiling ~20.9 on 26.1.5, unchanged from the old 21.5 — present-path wait-bound
  confirmed: GPU held 1100 MHz for 100% of samples in every run, fan auto-maxes (pwm 255)
  under load even in moderate mode. Power mode / fan / scx_lavd levers: **all dead** (A≈B≈E).
- Game's FSR3.1+FG = ~32.4 (~1.55x) and DOES show in the benchmark counter (engine frames).
- lsfg 2x does NOT show in the benchmark counter (layer frames); overlay read ~30 in open-
  world roaming — plausibly 2x of a ~15 fps street scene, but UNRESOLVED: needs a paired
  overlay reading (same spot, lsfg on/off) or a kernel-side present counter.
- **mesa 26.3.0-dev: +4.6% native (20.87→21.84) AND fixes a continuous UCHE TRANSLATION
  GPU-fault storm** seen on 26.1.5 (2 faults/run vs a constant stream). KEEP. Rollback:
  `pacman -U /var/cache/pacman/pkg/mesa-2:26.1.5-3-*.pkg.tar.zst` + same for vulkan-freedreno
  (note: the Vulkan driver is the separate `vulkan-freedreno` package, NOT `mesa`).
- DDR/GMU lever (08-14 item 5): **retired, experiment doesn't exist** — see
  docs/gmu-ddr-vote-experiment.md (kernel already votes DDR like mainline; only one GMU fw exists).
- **TRAP for future benching:** lsfg is toggled via /etc/pocknix/game-tweaks.json and the
  per-game block `games.<appid>` (with `enabled: true`) OVERRIDES `global` in the wrapper
  merge — check BOTH keys, and verify at the process level (`tr "\0" "\n" </proc/<pid>/environ |
  grep LSFGVK`): enabled = LSFGVK_ENV=1, disabled = DISABLE_LSFGVK=1.
- @ice's 41/48 remains unexplained by any lever we tested; his config/measuring-stick
  questions (drafted 08-14) are still the highest-information open item.

**SESSION 2026-08-16 PM — RESOLVED: lsfg presented-fps + recommended config.** The DPU
crtc framecount (`/sys/kernel/debug/dri/0/crtc-0/status` `total_framecount`, counts real
panel kickoffs) is a reliable presented-fps meter — the long-open "are lsfg frames
actually presented" question is ANSWERED: yes. Measured in gameplay (Arasaka tower):
**FSR3 Performance + game-FG OFF + lsfg 2x = 56.7 presented fps over a ~28.4 real base**
(game GPU 84%, ~29.6 ms/real frame = run K's 27.3 ms + ~2 ms lsfg — the 1.5 ms/frame layer
bench figure holds in-game). The game's own FSR3 FG costs ~16 ms/real frame by comparison
(42.33 presented ⇒ ~21 base vs 31.9 without FG) — **in-game FG is strictly worse than lsfg
here: fewer presented frames AND worse latency. RECOMMENDED AAA CONFIG: FSR3 Performance
upscale, in-game FG off, lsfg 2x.** Instrumentation details + revised GPU-bound model:
docs/present-path-attack-plan.md "INSTRUMENTATION RESULTS".

**Later 2026-08-16 session (different agent, in-game settings only): 42.33** with FSR3
upscaling at **Performance** quality (~640×360 internal) + FSR3 FG, 720p borderless,
mostly-Low + Medium textures (config read post-hoc from UserSettings.json; VSync=Off at
read time — unknown whether it was off during runs G/I above, so the 20.9 native baseline
may be stale). Two implications: (1) the 32.4 vs 42.33 delta is internal-render-resolution,
not a present-path change; (2) ~42 presents/s in the counter proves the present chain can
cycle at ~24 ms — the ~48 ms native floor is not a hard chain cap. Next native re-bench
must log the VSync value pre-run.

Goal: find more fps in Cyberpunk. This is the ready-to-run matrix plus what we already
know, so a bench session produces clean, comparable numbers instead of guesses.

## RESULTS — bench session 2026-08-15 evening (historical; its "wait-bound" reading was OVERTURNED by the 08-16 PM instrumentation above — the fps numbers stand, the interpretation doesn't)

All runs: in-game benchmark, 720p, FSR2 upscaling unless noted, Cliff driving, agent
sampling clocks/thermals/DPU counters over ssh. Each claim labeled PROVEN (measured) or
INFERRED (consistent but no isolated A/B).

| Run | Power | Compositor | Game FSR3-FG | lsfg 2x | Bench fps |
|-----|-------|-----------|--------------|---------|-----------|
| 1 | max | 120 | ON (see note) | off | 34.40 |
| 2 | max | 120 | off | off | 25.81 |
| 3 | max | 120 | off | on | 24.57 |
| 4 | max | 60 cap | ON | on | 32.25 |

Note on run 1: the FG state was mis-called live (the settings file had already been
rewritten by menu changes between runs). The numbers themselves settle it: 34.40 ≈ the
old FG-on 34.28, and 25.81 ≈ the old FG-off 25.6, both taken in balanced.

**PROVEN:**
- **`max` power mode adds ~0 fps in Cyberpunk.** FG-on: 34.28 (balanced) → 34.40 (max).
  FG-off: 25.6 (balanced) → 25.81 (max). GPU verified pinned at 1100 MHz for the entire
  run (sampled every 3 s, never dipped). GPU clock is not the bottleneck. [The original
  "wait-bound present-path ceiling CONFIRMED" reading here was WRONG — 08-16 PM fdinfo
  instrumentation showed the game ~91% GPU-busy: pinned-clock-with-no-gain means
  GPU-WORK-bound, not waiting. See INSTRUMENTATION RESULTS in present-path-attack-plan.md.]
- **`max` runs the prime cores at 99–103 °C** under bench load (cpu-1-0/1-1 thermal
  zones; little cluster showed mild capping 3.53→2.92 GHz; GPU unaffected). All heat,
  no fps: **shipping guidance for Cyberpunk-class titles = `balanced`.** `max` stays
  useful only for titles that actually GPU-bind.
- **gamescope composites at ~111 fps regardless of game fps** (DPU `pp_tx_done` irq
  count, debugfs `core_irq`, 10 s windows) — the portrait rotation shader runs ~4× per
  game frame. `gamescopectl debug_set_fps_limit 60` dropped panel commits to 49/s with
  **zero DPU errors** (dmesg clean; live-tunable, no restart).
- **The bench/overlay fps counter cannot see lsfg frames** (re-confirmed; run 3 reads
  ~= run 2).
- lsfg QAM toggle takes effect ONLY at game launch (wrapper env injection) — toggling
  mid-game does nothing. Relaunch to change it.

**INFERRED (strong, one control run short of proven):**
- **lsfg doubling verified at the panel:** with the 60-cap making gamescope commit only
  on new frames, panel commits = 49/s ≈ 2 × the 24.57 base. Missing control: same
  measurement with lsfg OFF (expect ~25/s). Run it next session.
- **@ice's 41/48 on Armada is an accounting difference, not a performance gap.** Same
  silicon (Ultra = capacity SKU); Armada's overlay shows presented (post-frame-gen)
  fps. Our presented rate with lsfg = ~49/s ≈ his 48. On presented frames we already
  match. Confirm his overlay semantics if the chance arises.
- 60-cap effect on BASE fps: NOT isolated (run 4 changed two variables vs run 1:
  −2.15 fps could be lsfg overhead, cap effect, or noise). Next session: FG all-off,
  cap 60, compare against 25.81.

**Recommendations to ship (pending the two control runs):**
1. Default power guidance stays `balanced`; document `max` as a per-title experiment.
2. Don't stack both frame-gens (interpolation-on-interpolation: artifacts + latency).
   Per-title: built-in FSR3-FG where the game has it (sees motion vectors); lsfg for
   everything else.
3. Consider `mangoapp_use_output_timing 1` as a pocknix default so the overlay shows
   presented fps (set live 2026-08-15, UNVALIDATED — check whether the overlay changed;
   resets on gamescope restart).
4. Consider a gamescope commit-cadence cap (the 111→49 composite cut) IF the control
   run shows base-fps gain; watch DPU errors over longer soaks before shipping.

**Device state note:** session ended with the device idle-suspending while still in
max/fan-max/60-cap; restore `balanced`/`moderate`/`debug_set_fps_limit 120` on next
wake (a watcher on fusor may have already done it — check `~/odin3-backups/restore-watch.log`).

## What we already know (don't re-derive)
- **The AAA native ceiling (~20–23 fps) is the display present-path, not GPU horsepower.**
  Prior investigation: GPU sat ~52% / CPU ~21% while the app frametime floored ~48 ms =
  *wait-bound*. `--immediate-flips` made it worse. The portrait panel forces gamescope's
  **rotation shader every frame** (`--use-rotation-shader`, no direct scanout) and the panel
  runs command-mode DSI — the young part of the mainline sm8750 display path. Two mesa
  generations (26.1.5 and 26.3-dev) changed nothing. So do NOT expect a driver/clock change
  to blow past the ceiling; expect incremental gains and lean on frame-gen for perceived fps.
- **Power mode during the prior benches: Cliff says `performance` (uncapped — GPU allowed
  the full 1100 MHz).** An earlier draft of this doc claimed "all prior numbers were taken
  in `balanced` (900 MHz cap)" — that was WRONG: it was inferred from reading the mode file
  at idle, *after* the benches, which says nothing about bench-time state, and it
  contradicted what Cliff had already said. Note `performance` is also the script's fallback
  default. So do NOT treat the old ~20–23 as clock-capped; `max` mode's only delta over
  `performance` is the min-freq pin (no mid-frame downclock) + CPU governor — a small
  expected gain, consistent with the wait-bound ceiling above.
- **@ice's ~41 fps is very likely frame-gen-assisted** (lsfg-vk doubling a ~20 fps base),
  not a native number. Confirm his exact setup before treating 41 as a native target.

## Confirmed levers (measured on-device 2026-08-15)
1. **Power mode.** `balanced` caps the GPU at **900 MHz**; `performance` (Cliff's mode
   during prior benches) is uncapped to **1100 MHz** with governors deciding. New **`max`**
   mode pins GPU min=max=1100 MHz (no mid-frame downclock) **and** sets the CPU governor to
   `performance`. Since prior runs were already uncapped, expect `max` to help only via the
   min-pin/governor — incremental, not +22%. Thermals are wide open at idle (GPU zones
   39–40 °C), so there's headroom to sustain it.
   - `pocknix-power-mode max` before benching; `pocknix-power-mode performance` after.
2. **Fan.** Default is `moderate`. For a sustained `max` run, set fan high/max so the GPU
   isn't thermally clipped mid-bench (`pocknix-fan-mode max` if present; else the QAM fan tile).
3. **Frame generation (perceived fps, already working).** lsfg-vk 2x is proven on this device
   (656 gen fps at 720p in the layer benchmark). It's the realistic path to a "smooth 40+"
   feel over a ~20 fps base. Toggle per-game in the QAM Games tab (Cyberpunk appid 1091500).
4. **Launch options are already clean** (`--launcher-skip` only — no PROTON_LOG/VKD3D_DEBUG
   debris to strip; verified 2026-08-15).
5. **FEX global profile = `default`** (TSO on) — correct; do NOT use `fast` (TSO off) on
   Cyberpunk (it caused the whole crash saga).

## The bench matrix (run each ~60 s in the SAME in-game scene, record fps + notes)
Use a fixed, repeatable scene (e.g. stand still in a known market/street). Record the
MangoHUD fps line and, if possible, `cat /sys/class/devfreq/3d00000.gpu/cur_freq` mid-run.

| # | Power mode | Fan | Frame-gen | Purpose |
|---|-----------|-----|-----------|---------|
| A | performance | (Cliff's usual) | off | baseline = reproduces the old ~20–23 number under prior conditions |
| B | max       | max      | off | tests the min-pin + governor + fan delta |
| C | max       | max      | on (2x) | perceived-fps ceiling with lsfg |
| D | (best native of A/B) | max | off, 720p/Low | confirm resolution/quality floor |

Between runs give the scene ~10 s to settle. Log the power mode WITH every fps number
(old numbers are worthless without it — this bit us before).

## How to read it
- If **B ≫ A**: mid-frame downclocking / governor latency was costing real fps; `max` is
  the answer and we ship guidance to use it for AAA.
- If **B ≈ A** (the likely outcome, given prior runs were already uncapped and wait-bound):
  confirms the present-path ceiling — clocks aren't the bottleneck. Then the only real win
  is **C (frame-gen)** and upstream mesa/display-path maturity over time.
- **C** is the number that matters for "does it feel good to play."

## Untried levers from the 2026-08-14 agent review (still open — only the max-mode tool was built)
- **scx_lavd vs schedutil A/B** — never tried.
- **Send the @ice questions** (his scene/settings, power+fan profile, `cur_freq` during
  play, panel refresh) — drafted in the 08-14 session, never posted. This decides whether
  41 fps is a real native target or frame-gen.
- **Fan-mode bench** — never actually benched under max fan (only noted as a to-do).
- The bench matrix above itself has **never been run** — no numbers exist for B/C/D.

## Deeper levers (later, not this session)
- **mesa-next 26.3.0-dev**: NOT currently on the device (only 26.1.5 installed). Prior A/B
  showed no fps change across mesa generations, so low priority — but it's the vehicle for
  future turnip A8xx perf commits (Gen8 first landed in mesa 26.0; the driver is young).
- **Present path**: a 60 Hz gamescope present cap or a cheaper rotation path could cut the
  composite tax, but removing `-r` earlier was what fixed the DPU ppdone/vblank timeouts —
  so any refresh/present change needs a careful DPU-error watch. Not a quick win.
- **DDR bandwidth votes / GMU** (7.1.3 vs 7.1.5): a kernel-bump-era experiment.

## One-liners
```
# before a max run
pocknix-power-mode max && pocknix-power-mode status
# watch GPU clock during a run (should hold 1100000000)
watch -n1 'cat /sys/class/devfreq/3d00000.gpu/cur_freq'
# restore after
pocknix-power-mode balanced
```
