// World Parameters settings for a world_fights --settings or a bb-game-probe --setup script.
// set(value, updateJS = false, updatePersistence = false): nothing is written to MSU#*.sav.
local g = @(id, v) ::WorldParameters.Mod.ModSettings.getSetting(id).set(v, false, false);
::WorldParametersE2E <- { WorldgenStart = ::Time.getExactTime() };
foreach (id in ["GlobalSettlementMult", "LargeSettlementMult", "MediumSettlementMult", "SmallSettlementMult", "CoastalSettlementMult", "CivilianSettlementMult", "MilitarySettlementMult"]) g(id, 5.0);
g("SettlementMinDistance", 6);
