#!/bin/sh
# sleepcycle-edge.sh pre|post <outdir> (2026-10-16): called from the temporary sleep.d hooks that sleep-cycle.sh installs.
# Snapshots at the suspend edge: qcom_stats counts, /proc/interrupts, and (pre) the interconnect / clock / regulator
# summaries = what every consumer holds at the moment our hooks have run and the kernel suspend begins.
P=$1; O=$2
for s in aosd cxsd ddr adsp cdsp slpi; do f=/sys/kernel/debug/qcom_stats/$s; [ -r "$f" ] && printf "%s=%s " "$s" "$(awk '/Count/{print $2}' "$f")"; done > "$O/qs-$P"
date -u +%T.%N >> "$O/qs-$P"
cp /proc/interrupts "$O/irq-$P.txt"
if [ "$P" = pre ]; then
  cp /sys/kernel/debug/interconnect/interconnect_summary "$O/icc-pre.txt" 2>/dev/null
  cp /sys/kernel/debug/clk/clk_summary "$O/clk-pre.txt" 2>/dev/null
  cp /sys/kernel/debug/regulator/regulator_summary "$O/reg-pre.txt" 2>/dev/null
fi
exit 0
