# Cyberpunk 2077 fps — bench plan & lever analysis (2026-08-15)

Goal: find more fps in Cyberpunk. This is the ready-to-run matrix plus what we already
know, so a bench session produces clean, comparable numbers instead of guesses.

## RESULTS — bench session 2026-08-15 evening (READ FIRST; supersedes expectations below)

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
  run (sampled every 3 s, never dipped). The wait-bound present-path ceiling from the
  earlier investigation is CONFIRMED — GPU clock is not the bottleneck.
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
- **All prior AAA numbers were taken in `balanced` power mode** (GPU capped at 900 MHz of
  1100, CPU ~78%) — so they undersell the hardware. That's the cheapest thing to fix.
- **@ice's ~41 fps is very likely frame-gen-assisted** (lsfg-vk doubling a ~20 fps base),
  not a native number. Confirm his exact setup before treating 41 as a native target.

## Confirmed levers (measured on-device 2026-08-15)
1. **Power mode (biggest free native lever).** `balanced` caps the GPU at **900 MHz**;
   the silicon has steps to **1100 MHz** (+22% clock). New **`max`** mode pins GPU
   min=max=1100 MHz (no mid-frame downclock) **and** sets the CPU governor to `performance`.
   Thermals are wide open at idle (GPU zones 39–40 °C), so there's headroom to sustain it.
   - `pocknix-power-mode max` before benching; `pocknix-power-mode balanced` after.
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
| A | balanced  | moderate | off | baseline = reproduces the old ~20–23 number |
| B | max       | max      | off | the free native win — GPU 1100 + CPU perf |
| C | max       | max      | on (2x) | perceived-fps ceiling with lsfg |
| D | (best native of A/B) | max | off, 720p/Low | confirm resolution/quality floor |

Between runs give the scene ~10 s to settle. Log the power mode WITH every fps number
(old numbers are worthless without it — this bit us before).

## How to read it
- If **B ≫ A**: the old numbers were just balanced-capped; `max` is the answer and we ship
  guidance to use it for AAA. Realistic native target: **mid-to-high 20s, maybe low 30s.**
- If **B ≈ A**: confirms the present-path ceiling — GPU clock isn't the bottleneck. Then the
  only real win is **C (frame-gen)** and upstream mesa/display-path maturity over time.
- **C** is the number that matters for "does it feel good to play."

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
