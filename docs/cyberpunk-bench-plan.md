# Cyberpunk 2077 fps — bench plan & lever analysis (2026-08-15)

Goal: find more fps in Cyberpunk. This is the ready-to-run matrix plus what we already
know, so a bench session produces clean, comparable numbers instead of guesses.

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
