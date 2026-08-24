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

Ported from ArmadaOS 2026-08-20..23 kernel push (kernel-22 bundle, 2026-08-24):
- **1005 rsinput-quiesce-the-mcu-across-system-sleep** — drops the MCU enable/reset
  GPIOs in rsinput_suspend() so it stops streaming before the GENI UART suspends;
  resume re-powers it via rsinput_init_commands(). Belt to 0513's suspenders — Armada
  carries both (their 1005+1006) and their GENI commit notes quiesce alone is not
  sufficient on devices whose MCU keeps TX alive. Verbatim from armada-packages d48faa9.
- **1006 rsinput-reassemble-uart-frames** — rsinput_rx() assumed one serdev callback ==
  one whole frame and threw away anything else; after resume, reception can start
  mid-frame and the pad stays dead until a callback happens to align ("intermittently
  dead controller after wake", "Checksum mismatch" bursts at resume — OUR symptom).
  Now buffers, resyncs on the frame header, delivers complete frames, keeps the tail.
  Verbatim from armada-packages d48faa9 (their 0515; renumbered after 1002 because its
  struct hunk needs the FF-bridge context). Candidate fix for controls-dead-after-resume.
- **0701 volup-no-wakeup-source** — only the power button wakes the device; volume-up
  no longer wakes from a bag/case. From armada-packages 6acedce.
  NOT taken from that push: their 1006 GENI mask (we already carry the equivalent 0513,
  more defensive: wakeup-capable check + error-path rebalance); 0513/0520 PCIe s2idle
  OPP floor (s2idle + SM8550 AOP specific — we do real S3 on SM8750); Linux 7.2 bump
  (separate, bigger decision).

NOTE: 0508 was spuriously "convicted" as the suspend wedge on 2026-08-08 (a module
bisection confounded by whether the charger was plugged in). It is a legitimate
controls-after-resume improvement and stays active via the ROCKNIX 20-sm8750 copy.
The GPU pair 0050/0051 in ../patches-disabled/ was jailed after an "overnight wedge"
that was very likely the same plugged-in confound — re-soak with 0519 before concluding.
