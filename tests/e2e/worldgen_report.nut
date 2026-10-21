// What worldgen produced, once the campaign has started. Reproduces the worldgen side of the
// world_parameters reports (triage/2026-10.md section 4: worldgen never finishes, #159625915, #172052138)
// and reports the highest faction ID: every extra village and noble house raises it, and the original
// game's battles break with a faction ID of 64 or more. The mod only warns about that in the log
// ("World Parameters: the highest faction ID is N, which is 64 or more ..."), so check that the warning
// is there whenever PROBE highest faction id below 64 = false.
//
// Mods: mod_msu (>= 1.8.0) and a world_parameters build. Settings: one of settings/*.nut.
// - Original game: bb-game-probe run_probe.py worldgen_report.nut --mode campaign --setup settings/X.nut
// - Modern engine: world_fights --settings settings/X.nut --world-script worldgen_report.nut
//
// A passing run (any settings) prints, among others:
//   PROBE wp loaded = true
//   PROBE city states = 3 or fewer, PROBE city states without faction = 0
//   PROBE duplicate settlement names = 0
// Reaching these lines at all means worldgen finished without hanging or throwing.

local function p( k, f )
{
	local v;
	try { v = f(); } catch (e) { v = "ERROR: " + e; }
	::logInfo("PROBE " + k + " = " + v);
}

local settlements = ::World.EntityManager.getSettlements();
local isCityState = @(_s) ::isKindOf(_s, "city_state");

p("wp loaded", @() ::Hooks.hasMod("mod_world_parameters"));
p("msu version", @() ::MSU.Version);
p("worldgen seconds (timing)", @() "WorldParametersE2E" in ::getroottable() ? ::Math.round(::Time.getExactTime() - ::WorldParametersE2E.WorldgenStart) : "n/a");
p("settlements", @() settlements.len());
p("civilian settlements", @() settlements.filter(@(_, _s) !_s.isMilitary() && !isCityState(_s)).len());
p("military settlements", @() settlements.filter(@(_, _s) _s.isMilitary()).len());
p("city states", @() settlements.filter(@(_, _s) isCityState(_s)).len());
p("city states without faction", @() settlements.filter(@(_, _s) isCityState(_s) && _s.getOwner() == null).len());
p("factions", @() ::World.FactionManager.m.Factions.len());
p("highest faction id", @() ::World.FactionManager.m.Factions.len() - 1);
p("highest faction id below 64", @() ::World.FactionManager.m.Factions.len() - 1 < 64);
p("duplicate settlement names", function() {
	local seen = {};
	local dupes = 0;
	foreach (s in settlements) {
		if (s.getName() in seen) ++dupes;
		seen[s.getName()] <- true;
	}
	return dupes;
});
p("numbered settlement names", function() {
	local ret = [];
	local numeral = regexp("^[IVXLCDM]+$");
	foreach (s in settlements) {
		local words = split(s.getName(), " ");
		if (words.len() > 1 && numeral.match(words[words.len() - 1])) ret.push(s.getName());
	}
	ret.sort();
	return ret.len() + (ret.len() == 0 ? "" : " " + ret.reduce(@(_a, _b) _a + "," + _b));
});
p("guaranteed buildings (fletcher temple barber kennel taxidermist)", function() {
	local b = ::Const.World.Buildings;
	return b.Fletchers + " " + b.Temples + " " + b.Barbers + " " + b.Kennels + " " + b.Taxidermists;
});
p("settlement names", function() {
	local names = settlements.map(@(_s) _s.getName());
	names.sort();
	return names.reduce(@(_a, _b) _a + "," + _b);
});

// A fingerprint of the map, for checking that the same seed and settings give the same map every run
// (determinism.sh): every settlement's name and tile, and every faction's name, in a fixed order.
// "map hash" is short enough for any log line; "map" is the full text, through ::ClaudeProbe.out when
// it exists (the original's log cuts lines at about 3000 bytes).
local function hash( _text ) {
	local h = 0;
	foreach (c in _text) h = (h * 31 + c) % 16777213; // stays below 2^31, no overflow
	return h;
}
local map = [];
foreach (s in settlements) {
	local tile = s.getTile();
	map.push(s.getName() + "@" + tile.SquareCoords.X + "," + tile.SquareCoords.Y);
}
map.sort();
local factions = [];
foreach (f in ::World.FactionManager.m.Factions) {
	if (f != null) factions.push(f.getID() + ":" + f.getName());
}
local mapText = map.reduce(@(_a, _b) _a + ";" + _b) + "|" + factions.reduce(@(_a, _b) _a + ";" + _b);
p("map hash", @() hash(mapText));
if ("ClaudeProbe" in ::getroottable()) ::ClaudeProbe.out("map", mapText);
else ::logInfo("PROBE map = " + mapText);
