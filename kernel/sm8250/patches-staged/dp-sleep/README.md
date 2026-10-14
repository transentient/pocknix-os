# dp-sleep: DisplayPort across a docked sleep, part (b) - STAGED 2026-10-14

Part (a) is in the build: 40-holodor/0724 (kernel 27) keeps the PD link alive across suspend (the PMIC
irq latched during sleep is wiped on resume; the dock's second DP Attention sat unread in the PD PHY
rx buffer and PD was dead until replug, so the sink's retrain request was never serviced and the
resume's link training ran into AUX timeouts).

0725 here is part (b), written from the downstream driver's behaviour, compile-tested only:
- Type-C Attention with HPD high while connected -> EV_IRQ_HPD_INT (sink status read, link
  maintenance when the sink asks), instead of being ignored.
- sink to D3 (DP_SET_POWER) before a DRM-initiated off with the sink attached (suspend), D0 before the
  re-enable's forced training.

Promote only on evidence from the rig (scratchpad dock-cycle.sh on kernel 27):
- PD alive after the wake (no "RX message pending", pd ack=00) AND the picture still dark -> try 0725.
- Picture back on 27 alone -> leave 0725 here; the resume's own full link training was enough.
Risks to watch when promoted: a spurious IRQ_HPD costs a few AUX reads; a D3 write to a dongle that
already lost its monitor is harmless (sink_count == 0 path already does it); a sink that refuses D0
(AUX dead) fails training exactly as today.
