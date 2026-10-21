// World Parameters settings for a world_fights --settings or a bb-game-probe --setup script.
// set(value, updateJS = false, updatePersistence = false): nothing is written to MSU#*.sav.
local g = @(id, v) ::WorldParameters.Mod.ModSettings.getSetting(id).set(v, false, false);
::WorldParametersE2E <- { WorldgenStart = ::Time.getExactTime() };
g("NumFactions", 4); g("MinSouthern", 3); g("GlobalSettlementMult", 2.2);
g("SettlementMinDistance", 8); g("SouthernMinDistance", 24);
