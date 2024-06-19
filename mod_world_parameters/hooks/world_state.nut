// ::WorldParameters.MH.hook("scripts/states/world_state", function(q) {
// 	q.startNewCampaign = @(__original) function() {
// 		local worldmap = ::MapGen.get("world.worldmap_generator");
// 		worldmap.m.MinX = ::WorldParameters.Mod.ModSettings.getSetting("SizeX").getValue();
// 		worldmap.m.MinY = ::WorldParameters.Mod.ModSettings.getSetting("SizeY").getValue();
// 		return __original();
// 	}
// });
