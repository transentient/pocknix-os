import { PanelSection } from "@decky/ui";
import type { Dispatch, SetStateAction } from "react";
import { setFanMode, setLavdMode, setPowerMode, setChargeLimit } from "../backend";
import { SelectEdit } from "../components/widgets";
import type { Config } from "../types";

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
  return (
    <PanelSection title="PERFORMANCE">
      <SelectEdit label="Power Profile" value={config.powerMode} options={powerOptions} onChange={(mode) => applyMode(setPowerMode, mode)} />
      <SelectEdit label="Charge Limit" value={config.chargeLimit} options={chargeOptions} onChange={(pct) => applyCharge(pct as number)} />
      <SelectEdit label="Fan Curve" value={config.fanMode} options={fanOptions} onChange={(mode) => applyMode(setFanMode, mode)} />
      <SelectEdit label="CPU Scheduler" value={config.lavdMode} options={lavdOptions} onChange={(mode) => applyMode(setLavdMode, mode)} />
    </PanelSection>
  );
}
