// World Parameters requires MSU >= 1.8.0: MSU up to 1.7.2 shares one array between the world combat
// faction slots 32-255, which is what breaks world-map fights and saves on maps with extra settlements
// (triage/2026-10.md section 4: #144853050, #146016390, #145500636, #146402142, #148916396).
//
// Mods: a world_parameters build plus either held:mod_msu (1.9.0) or an MSU 1.7.2 zip. Menu mode.
// - With MSU 1.9.0 a passing run prints:
//     PROBE msu version = 1.9.0
//     PROBE wp registered = true
//     PROBE wp set up = true
//     PROBE wp requires msu = mod_msu >= 1.8.0
// - With MSU 1.7.2, Modern Hooks logs the error "mod_msu (...) version 1.7.2 is outdated for
//   mod_world_parameters (World Parameters), which requires versions greater than or equal to 1.8.0: ..."
//   and "Errors occured when validating mod compatibility", and shows a popup whose only way out is to
//   quit the game. It still runs the queue, so a headless probe gets to the menu: PROBE msu version =
//   1.7.2, wp set up = true (verified in the original game 2026-10-21). The refusal is the popup.

local function p( k, f )
{
	local v;
	try { v = f(); } catch (e) { v = "ERROR: " + e; }
	::logInfo("PROBE " + k + " = " + v);
}

p("msu version", @() "MSU" in ::getroottable() ? ::MSU.Version : "not loaded");
p("wp registered", @() ::Hooks.hasMod("mod_world_parameters"));
p("wp set up", @() "WorldParameters" in ::getroottable() && "Mod" in ::WorldParameters);
p("wp requires msu", function() {
	foreach (data in ::Hooks.getMod("mod_world_parameters").getCompatibilityData()) {
		if (data.getModID() == "mod_msu") return data.getModID() + " " + data.getErrorString();
	}
	return "none";
});
