import { PanelSection } from "@decky/ui";
import type { Dispatch, SetStateAction } from "react";
import { setFanMode, setLavdMode, setPowerMode, setChargeLimit, setLedColor, setLedMode } from "../backend";
import { ColorPalette, SelectEdit } from "../components/widgets";
import type { Config } from "../types";

// Modes the stick-LED daemon understands (pocknix-stick-ledsd reads /var/lib/pocknix/led-mode).
const ledEffectOptions = [
  { data: "off", label: "Off" },
  { data: "static", label: "Static" },
  { data: "rainbow", label: "Rainbow" },
  { data: "breathe", label: "Breathing" },
];
const ledColorPresets = [
  { data: "ff6600", label: "Hodor Orange" },
  { data: "ff0000", label: "Red" },
  { data: "ffff00", label: "Yellow" },
  { data: "00ff00", label: "Green" },
  { data: "00ffff", label: "Cyan" },
  { data: "0066ff", label: "Blue" },
  { data: "8800ff", label: "Purple" },
  { data: "ff00aa", label: "Pink" },
  { data: "ffffff", label: "White" },
];
const chargeOptions = [
  { data: 80, label: "80% (longest battery lifespan)" },
  { data: 85, label: "85%" },
  { data: 90, label: "90%" },
  { data: 100, label: "100% (charge to full)" },
];
const powerOptions = [
  { data: "eco", label: "Eco (cool & quiet, ~60% clocks)" },
  { data: "balanced", label: "Balanced (~80% clocks)" },
  { data: "performance", label: "Performance (uncapped)" },
];
const fanOptions = [
  { data: "quiet", label: "Quiet" },
  { data: "moderate", label: "Moderate" },
  { data: "performance", label: "Performance" },
  { data: "max", label: "Max (always 100%)" },
];
const lavdOptions = [
  { data: "autopilot", label: "Autopilot" },
  { data: "performance", label: "Performance" },
];

export function Power({ config, setConfig, reload }: {
  config: Config;
  setConfig: Dispatch<SetStateAction<Config | null>>;
  reload: () => void;
}) {
  const applyLedMode = async (mode: string) => {
    try {
      const next = await setLedMode(mode);
      setConfig((current) => (current ? { ...current, ledMode: next.ledMode } : current));
    } catch (error) {
      reload();
    }
  };
  const applyLed = async (hex: string) => {
    try {
      const next = await setLedColor(hex);
      setConfig((current) => (current ? { ...current, ledColor: next.ledColor } : current));
    } catch (error) {
      reload();
    }
  };
  const applyCharge = async (pct: number) => {
    try {
      const next = await setChargeLimit(pct);
      setConfig((current) => (current ? { ...current, chargeLimit: next.chargeLimit } : current));
    } catch (error) {
      reload();
    }
  };
  const applyMode = async (setter: (mode: string) => Promise<Config>, mode: string) => {
    try {
      const next = await setter(mode);
      setConfig((current) => (current ? { ...current, fanMode: next.fanMode, powerMode: next.powerMode, lavdMode: next.lavdMode } : current));
    } catch (error) {
      reload();
    }
  };
  // Rainbow ignores the color; off shows nothing — only offer the palette when it matters.
  const ledColorRelevant = config.ledMode === "static" || config.ledMode === "breathe";
  return (
    <>
      <PanelSection title="PERFORMANCE">
        <SelectEdit label="Power Profile" value={config.powerMode} options={powerOptions} onChange={(mode) => applyMode(setPowerMode, mode)} />
        <SelectEdit label="Charge Limit (experimental)" value={config.chargeLimit} options={chargeOptions} onChange={(pct) => applyCharge(pct as number)} />
        <SelectEdit label="Fan Curve" value={config.fanMode} options={fanOptions} onChange={(mode) => applyMode(setFanMode, mode)} />
        <SelectEdit label="CPU Scheduler" value={config.lavdMode} options={lavdOptions} onChange={(mode) => applyMode(setLavdMode, mode)} />
      </PanelSection>
      <PanelSection title="STICK LEDS">
        <SelectEdit label="Effect" value={config.ledMode} options={ledEffectOptions} onChange={(mode) => applyLedMode(mode as string)} />
        {ledColorRelevant && (
          <ColorPalette colors={ledColorPresets} value={config.ledColor} onChange={(hex) => applyLed(hex)} />
        )}
      </PanelSection>
    </>
  );
}
