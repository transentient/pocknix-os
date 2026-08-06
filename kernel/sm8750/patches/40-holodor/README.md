# 40-holodor — Odin 3 rumble/haptics + suspend robustness (ported from Armada)

Sourced from armada-os/armada-packages `kernel/patches` (GPL-2.0, credit ArmadaOS —
they did the hard part: the PMIH0108 hv-haptics bring-up and the rsinput FF bridge,
including the atomic-sleep crash fix). 0700 is ours: the combined DTS delta
(hv-haptics + SDAM nodes and the gamepad rumble/deadzone properties), regenerated
against the ROCKNIX CQ8725S tree this stack applies on.

- 0044: don't power off PCIe GDSCs during suspend (ath12k Wi-Fi rides PCIe —
  candidate fix for the intermittent suspend wedge)
- 0508: rsinput reinitializes the MCU on resume (kernel-level cure for
  controls-dead-after-resume; the InputPlumber sleep-post retry stays as belt+braces)
- 1000..1004: qcom-hv-haptics driver + fixes; 1002 = rsinput force-feedback bridge
- 1300: rsinput analog deadzone support (DT-configurable, see 0700)

Requires CONFIG_INPUT_QCOM_HV_HAPTICS=m (config/linux.aarch64.conf).
