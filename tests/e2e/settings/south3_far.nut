// World Parameters settings for a world_fights --settings or a bb-game-probe --setup script.
// set(value, updateJS = false, updatePersistence = false): nothing is written to MSU#*.sav.
local g = @(id, v) ::WorldParameters.Mod.ModSettings.getSetting(id).set(v, false, false);
::WorldParametersE2E <- { WorldgenStart = ::Time.getExactTime() };
g("MinSouthern", 3); g("SouthernMinDistance", 36);
