// Vanilla's settlement.getRandomName draws names until it finds one no settlement has, with no limit on
// the tries, so it never returns once every name in a settlement type's list (19 to 40 names, 3 for city
// states) is taken. That is the "worldgen never finishes" report (triage/2026-10.md section 4: #159625915,
// #172052138). This probe calls it in a started world with a list of names that are all taken.
//
// Mods: mod_msu and a world_parameters build, any settings. Campaign mode.
// - Original game: bb-game-probe run_probe.py names_exhausted.nut --mode campaign
// - Modern engine: world_fights --world-script names_exhausted.nut --days 0
//
// Fixed build:
//   PROBE names: free name = <the free name>
//   PROBE names: all taken, numbered = true
//   PROBE names: all taken, unique = true
// Unfixed build: the second call never returns (the run hangs until its timeout).

local function p( k, f )
{
	local v;
	try { v = f(); } catch (e) { v = "ERROR: " + e; }
	::logInfo("PROBE " + k + " = " + v);
}

local settlements = ::World.EntityManager.getSettlements();
local taken = [settlements[0].getName(), settlements[1].getName()];
p("names: free name", @() settlements[0].getRandomName(["Claude Probe Free Name"].extend(taken)));
local name = null;
p("names: all taken, numbered", function() {
	name = settlements[0].getRandomName(taken);
	return name == taken[0] + " II" || name == taken[1] + " II";
});
p("names: all taken, unique", @() settlements.filter(@(_, _s) _s.getName() == name).len() == 0);
