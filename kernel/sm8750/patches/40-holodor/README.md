# 40-holodor — Holodor-original kernel patches (not from the ROCKNIX sync)

`20-sm8750/` is regenerated from ROCKNIX by `sync.sh` and is the single source of
truth for anything ROCKNIX ships (incl. 0030 HTR3212 LEDs, 0044 PCIe-GDSC retention,
0508 rsinput resume-reinit — do NOT re-add copies here). This dir holds only patches
Holodor carries that ROCKNIX does not.

Suspend/USB-C (the hard-won ones):
- **0519 usb-typec-ucsi-clear-USB-role** — THE fix for the intermittent plugged-in
  suspend wedge. A 7.1.x UCSI regression left the USB data role uncleared for a
  charger-only Type-C partner on SM8750, keeping the USB power island up across
  suspend so deep-sleep power-collapse hard-hung the SoC. Only ever hung WHILE PLUGGED
  IN — which is why it looked random for a week. 2-line revert. Credit: ArmadaOS (aanzdev).
  Confirmed on hardware: plugged-in rtcwake soak 4/4 clean.
- **0513 geni-mask-non-console-irq-on-suspend** — masks the gamepad UART's IRQs across
  suspend so a wake-time IRQ storm can't permanently kill the rsinput UART. This is a
  CONTROLS-DEAD fix, not the wedge fix (its earlier "makes 0508 safe" framing was
  contaminated by cable-state variance — 0508 was never the wedge; 0519 was).

Other Holodor-original:
- 0605 wcd939x headsets-via-USBSS; 0700 Odin3 haptics/rumble DTS; 1000-1004 qcom-hv-
  haptics + rsinput FF bridge; 1300 rsinput deadzone.

NOTE: 0508 was spuriously "convicted" as the suspend wedge on 2026-08-08 (a module
bisection confounded by whether the charger was plugged in). It is a legitimate
controls-after-resume improvement and stays active via the ROCKNIX 20-sm8750 copy.
The GPU pair 0050/0051 in ../patches-disabled/ was jailed after an "overnight wedge"
that was very likely the same plugged-in confound — re-soak with 0519 before concluding.
