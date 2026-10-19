#!/bin/sh
# Holodor: switch ROCKNIX ABL boot mode to Linux (Holodor) and reboot from Android.
# Run via Settings > Odin settings > Run script as Root > boot_holodor.sh
sh -c 'DEV=/dev/block/by-name/devinfo; OFF=$(grep -abo "BootMode" "$DEV" 2>/dev/null | head -n 1 | cut -d: -f1); [ -n "$OFF" ] && [ "$OFF" -ge 2456 ] && printf "\x00" | dd of="$DEV" bs=1 seek=$((OFF + 56)) count=1 conv=notrunc 2>/dev/null && sync && (svc power reboot 2>/dev/null || reboot)'
