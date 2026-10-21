// Vanilla's guaranteeAllBuildingsInSettlements throws ("the index '0' does not exist") when a guaranteed
// building exists fewer than twice and no settlement can take another one. That aborted the campaign
// start and left the loading screen up (worldgen never finishes, triage/2026-10.md section 4; seen at
// settlement spacing 18 and with forced coastal city states). Which maps hit it depends on the seed and
// the settings, so this probe builds the situation directly in a started world: every military
// settlement's free building slots are filled, and the kennel count is set to 1.
//
// Mods: mod_msu and a world_parameters build, any settings. Campaign mode (the probe changes the world,
// so run it last and don't save afterwards).
// - Original game: bb-game-probe run_probe.py guarantee_buildings.nut --mode campaign
// - Modern engine: world_fights --world-script guarantee_buildings.nut --days 0
//
// Fixed build:
//   PROBE guarantee: kennel candidates left = 0
//   PROBE guarantee: call = ok
//   PROBE guarantee: kennel count after = 1
// Unfixed build: PROBE guarantee: call = ERROR: the index '0' does not exist (or similar)

local function p( k, f )
{
	local v;
	try { v = f(); } catch (e) { v = "ERROR: " + e; }
	::logInfo("PROBE " + k + " = " + v);
}

local military = ::World.EntityManager.getSettlements().filter(@(_, _s) _s.isMilitary());
p("guarantee: military settlements", @() military.len());
p("guarantee: fill free slots", function() {
	local added = 0;
	foreach (s in military) {
		while (s.hasFreeBuildingSlot()) {
			s.addBuilding(::new("scripts/entity/world/settlements/buildings/temple_building"));
			++added;
		}
	}
	return added;
});
p("guarantee: kennel candidates left", @() military.filter(@(_, _s) _s.hasFreeBuildingSlot() && !_s.hasBuilding("building.kennel")).len());

local saved = {};
foreach (key in ["Fletchers", "Temples", "Barbers", "Kennels", "Taxidermists"]) {
	saved[key] <- ::Const.World.Buildings[key];
	::Const.World.Buildings[key] = 2; // the others are skipped, as on a map that has them
}
::Const.World.Buildings.Kennels = 1;
p("guarantee: call", function() {
	::MapGen.get("world.worldmap_generator").guaranteeAllBuildingsInSettlements();
	return "ok";
});
p("guarantee: kennel count after", @() ::Const.World.Buildings.Kennels);
foreach (key, value in saved) {
	::Const.World.Buildings[key] = value;
}
