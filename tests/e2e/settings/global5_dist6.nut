// World Parameters settings for a world_fights --settings or a bb-game-probe --setup script.
// First every World Parameters setting goes back to its default, then this config's values are applied, so
// no value MSU loaded from a stored MSU#*.sav (on the original game, the user's own) leaks into the test.
// set(value, updateJS = false, updatePersistence = false): nothing is written to MSU#*.sav.
foreach (s in ::WorldParameters.Mod.ModSettings.getAllElementsAsArray(@(_key, _e) "IsSetting" in _e.Data)) s.set(s.BaseValue, false, false);
local g = @(id, v) ::WorldParameters.Mod.ModSettings.getSetting(id).set(v, false, false);
::WorldParametersE2E <- { WorldgenStart = ::Time.getExactTime() };
g("GlobalSettlementMult", 5.0); g("SettlementMinDistance", 6);
