# setup-NOMSM.sh (2026-10-18): cycle "S2 + no msm". Opus's S2 config (audio DSP stopped, wifi PCIe link down: the only
# config whose APPS sleep set reaches xo.lvl 0), then the GPU and the display subsystem UNBOUND so neither the GMU's RSC
# nor the display pipeline is live at the flush (CONFIG_DRM_MSM=y: unbind is the only way without a new boot image).
# Must run UNDOCKED on battery (VBUS keeps dwc3 active = XO held). teardown-Q reboots the device afterwards.
sh /var/tmp/rp5-power/setup-Q.sh
echo "-- stopping the game session (DRM clients must be gone before the unbind)"
for u in $(systemctl --user -M deck@.host list-units --no-legend --plain 2>/dev/null | awk '/gamescope|steam|pocknix-session|plasma|kwin/ {print $1}'); do
  systemctl --user -M deck@.host stop "$u" 2>/dev/null && echo "   stopped $u"
done
systemctl stop gamescope-session.service pocknix-session.service sddm.service plymouth-quit-wait.service 2>/dev/null
sleep 3
echo "-- drm clients left: $(awk 'NR>1 && NF {n++} END {print n+0}' /sys/kernel/debug/dri/0/clients 2>/dev/null)"
for p in $(fuser /dev/dri/card0 /dev/dri/renderD128 2>/dev/null); do echo "   killing drm holder pid $p ($(cat /proc/$p/comm 2>/dev/null))"; kill $p 2>/dev/null; done
sleep 2
if [ -e /sys/bus/platform/drivers/adreno/3d00000.gpu ]; then echo 3d00000.gpu > /sys/bus/platform/drivers/adreno/unbind && echo "   gpu unbound (the DRM aggregate goes with it)"; else echo "   gpu already not bound"; fi
sleep 2
if [ -e /sys/bus/platform/drivers/msm-mdss/ae00000.display-subsystem ]; then echo ae00000.display-subsystem > /sys/bus/platform/drivers/msm-mdss/unbind && echo "   mdss unbound"; else echo "   mdss already not bound"; fi
sleep 3
echo "-- after unbind: dri0 $( [ -e /dev/dri/card0 ] && echo still-present || echo gone ); mdss_gdsc/gpu genpd:"
grep -E '^(mdss_gdsc|gpu_cx_gdsc|gpu_gx_gdsc|gfx|mmcx|cx|mx)\b' /sys/kernel/debug/pm_genpd/pm_genpd_summary | awk '{printf "   %-14s %s\n", $1, $2}'
echo "   bi_tcxo=$(cat /sys/kernel/debug/clk/bi_tcxo/clk_prepare_count) disp_cc_mdss_ahb_clk=$(cat /sys/kernel/debug/clk/disp_cc_mdss_ahb_clk/clk_prepare_count) gpu_cc_cx_gmu_clk=$(cat /sys/kernel/debug/clk/gpu_cc_cx_gmu_clk/clk_prepare_count 2>/dev/null)"
