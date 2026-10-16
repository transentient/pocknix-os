#!/bin/bash
# rpmh-votes-dump.sh (2026-10-16), run ON the RP5 as root with rpmh_peek.ko loaded (kernel 52 debug build):
# the APPS DRV's current vote for every cmd-db ARC level and VRM resource: voltage(+0) enable(+4) mode(+8);
# XO buffers (lnbclk/rfclk/...) are VRM resources whose enable is +4.
# SAFETY (10-16 ~20:00): a read the firmware never answers keeps one of the 2 AMC TCSes forever; the BCM MC1
# read did that and the next read wedged every active RPMh vote (forced restart). BCMs are never read, the
# timer registers are skipped, and the script STOPS at the first ERR so one TCS stays free.
P=/sys/kernel/debug/rpmh_peek
[ -d $P ] || { echo "rpmh_peek not loaded"; exit 1; }
rd() { echo "$1" > $P/addr; cat $P/value 2>/dev/null || { echo "ERR at $1: stopping (one AMC TCS may be held now: reboot)" >&2; kill -TERM $$; }; }
grep -E '^0x[0-9a-f]+: ' /sys/kernel/debug/cmd-db | while read -r a n rest; do
  a=${a%:}; t=$(( (a >> 16) & 7 ))
  case $t in
    3) case $n in *.tmr) ;; *) echo "ARC $n $a level=$(rd $a)" ;; esac ;;
    4) echo "VRM $n $a mV=$(rd $a) en=$(rd $(printf 0x%x $((a + 4)))) mode=$(rd $(printf 0x%x $((a + 8))))" ;;
    *) ;;   # BCMs (5) are never read; entries with address 0 have no resource
  esac
done
