#!/bin/bash
# rpmh-votes-dump.sh (2026-10-16), run ON the RP5 as root with rpmh_peek.ko loaded (kernel 52 debug build):
# every cmd-db resource with the APPS DRV's current vote. ARC/BCM: one register. VRM: voltage(+0) enable(+4)
# mode(+8) headroom(+0xc); XO buffers (lnbclk/rfclk/...) are VRM resources whose enable is +4.
P=/sys/kernel/debug/rpmh_peek
[ -d $P ] || { echo "rpmh_peek not loaded"; exit 1; }
rd() { echo "$1" > $P/addr; cat $P/value 2>/dev/null || echo ERR; }
grep -E '^0x[0-9a-f]+: ' /sys/kernel/debug/cmd-db | while read -r a n rest; do
  a=${a%:}; t=$(( (a >> 16) & 7 ))
  case $t in
    3) echo "ARC $n $a level=$(rd $a)" ;;
    5) echo "BCM $n $a vote=$(rd $a)" ;;
    4) echo "VRM $n $a mV=$(rd $a) en=$(rd $(printf 0x%x $((a + 4)))) mode=$(rd $(printf 0x%x $((a + 8)))) hr=$(rd $(printf 0x%x $((a + 12))))" ;;
    *) echo "??? $n $a" ;;
  esac
done
