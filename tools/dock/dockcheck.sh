#!/bin/bash
# dockcheck.sh — the dock test matrix, run from fusor (dev only).
#
#   dockcheck.sh <rp5|odin3> prep                  put the test tone on the device
#   dockcheck.sh <rp5|odin3> state                 DP connector, default sink, sinks, profile, recent audio errors
#   dockcheck.sh <rp5|odin3> frame [name]          grab one frame from the HDMI capture, report its brightness
#   dockcheck.sh <rp5|odin3> tone [secs]           play the tone on the device's default sink, record the capture, report
#   dockcheck.sh <rp5|odin3> speaker [secs]        play the tone on the device, report whether the stream ran (no ear)
#   dockcheck.sh <rp5|odin3> wait <enabled|disabled> [timeout-s]
#   dockcheck.sh <rp5|odin3> run <label>           state + frame + tone, one PASS/FAIL line appended to results
#
# Eye: the UGREEN dock's HDMI into the MACROSILICON capture on fusor (/dev/video0, 1080p60 YUYV;
# ALSA card "Video" for HDMI audio). The first frames after a mode change are black (dongle lock),
# so `frame` waits 2 s. Plug/unplug is Cliff's; this script only measures.
# Results: tools/dock/results-<device>-<date>.md (append-only, one line per `run`).
set -o pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
DEV=$1; CMD=$2; shift 2 2>/dev/null
case "$DEV" in
  rp5)   IP=192.168.1.68 ;;
  odin3) IP=192.168.1.32 ;;
  *) sed -n 2,12p "$0"; exit 2 ;;
esac
SSH="ssh -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 deck@$IP"
CAP_AUDIO=${CAP_AUDIO:-hw:Video,0}
CAP_VIDEO=${CAP_VIDEO:-/dev/video0}
OUT=${DOCK_OUT:-$HOME/dock-runs/$DEV}; mkdir -p "$OUT"
RES="$HERE/results-$DEV-$(date +%F).md"
TONE_HZ=1000

dp_state() { $SSH 'for c in /sys/class/drm/card*-DP-*; do [ -e "$c/status" ] && echo "$(basename $c) status=$(cat $c/status) enabled=$(cat $c/enabled)"; done' 2>/dev/null; }

case "$CMD" in
  prep)
    python3 - <<'EOF' > /tmp/dock-tone.wav
import math, struct, sys, wave
fs=48000; secs=4; f=1000; a=0.3
w=wave.open(sys.stdout.buffer,'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(fs)
w.writeframes(b''.join(struct.pack('<hh', int(a*32767*math.sin(2*math.pi*f*i/fs)), int(a*32767*math.sin(2*math.pi*f*i/fs))) for i in range(fs*secs)))
w.close()
EOF
    scp -q /tmp/dock-tone.wav deck@$IP:/tmp/dock-tone.wav && echo "tone on $DEV:/tmp/dock-tone.wav" ;;

  state)
    echo "== $DEV $(date +%T) =="
    dp_state
    $SSH 'echo "default sink: $(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -m1 node.name | cut -d\" -f2)";
          echo "sinks:"; pactl list short sinks 2>/dev/null | cut -f2 | sed "s/^/  /";
          echo "card profiles:"; pactl list cards 2>/dev/null | grep -E "Name: alsa_card|Active Profile|^\s+(HiFi|HDMI|off)" | sed "s/^\s*/  /";
          echo "watcher: $(systemctl --user is-active pocknix-dp-audio-watch.service 2>/dev/null)";
          echo "recent audio errors (kernel, 5 min):"; journalctl -k --since -5min --no-pager 2>/dev/null | grep -iE "q6afe|hdmi-audio|dp_audio|DISPLAY_PORT|auto_null|acp" | tail -8 | sed "s/^/  /"' ;;

  frame)
    name=${1:-frame}; f="$OUT/$(date +%H%M%S)-$name.png"
    sleep 2
    sudo ffmpeg -loglevel error -f v4l2 -i "$CAP_VIDEO" -frames:v 1 -y "$f" 2>/dev/null
    [ -s "$f" ] || { echo "frame: no capture on $CAP_VIDEO"; exit 1; }
    y=$(ffmpeg -loglevel error -i "$f" -vf "signalstats,metadata=print:file=-" -f null - 2>/dev/null | grep -m1 'YAVG' | cut -d= -f2)
    v=$(printf '%.0f' "$y"); echo "frame: YAVG $v -> $f $( [ "$v" -gt 20 ] && echo VIDEO || echo BLACK )" ;;

  tone)
    secs=${1:-4}; w="$OUT/$(date +%H%M%S)-tone.wav"
    ( sudo arecord -q -D "$CAP_AUDIO" -f S16_LE -c 2 -r 48000 -d $((secs+1)) "$w" ) &
    sleep 0.5; $SSH "pw-play /tmp/dock-tone.wav" ; wait
    [ -s "$w" ] || { echo "tone: no capture on $CAP_AUDIO"; exit 1; }
    lvl=$(python3 "$HERE/../rp5-audio/wavlevel.py" "$w" $TONE_HZ); echo "tone: $lvl"
    med=$(echo "$lvl" | sed -n 's/.*median \([-0-9.]*\) dBFS.*/\1/p'); python3 -c "import sys; sys.exit(0 if float('$med') > -40 else 1)" && echo "tone: HEARD on the capture" || echo "tone: SILENT on the capture" ;;

  speaker)
    $SSH 'pw-play /tmp/dock-tone.wav & sleep 2; pw-dump 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
for o in d:
    p=o.get(\"info\",{}).get(\"props\",{})
    if p.get(\"media.class\")==\"Stream/Output/Audio\" and \"dock-tone\" in str(p.get(\"media.name\",\"\"))+str(p.get(\"application.name\",\"\")):
        print(\"stream:\", o[\"info\"][\"state\"], \"->\", p.get(\"target.object\",\"default\"))
"; wait' ;;

  wait)
    want=$1; t=${2:-60}; for ((i=0;i<t;i++)); do s=$(dp_state); case "$s" in *"enabled=$want"*) echo "DP $want after $i s: $s"; exit 0;; esac; sleep 1; done; echo "TIMEOUT waiting for DP $want: $s"; exit 1 ;;

  run)
    label=${1:?label}; echo "## $label $(date '+%F %T')" | tee -a "$RES"
    { "$0" $DEV state; "$0" $DEV frame "$label"; "$0" $DEV tone; } 2>&1 | tee "$OUT/$(date +%H%M%S)-$label.log" | tee -a "$RES" ;;

  *) sed -n 2,12p "$0"; exit 2 ;;
esac
