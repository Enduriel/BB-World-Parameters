::WorldParameters <- {
	ID = "mod_world_parameters",
	Name = "World Parameters",
	Version = "1.0.0"
}
::WorldParameters.MH <- ::Hooks.register(::WorldParameters.ID, ::WorldParameters.Version, ::WorldParameters.Name);
::WorldParameters.MH.require("mod_msu >= 1.3.0");
::WorldParameters.MH.conflictWith("mod_legends [Legends uses its own custom world generation system and settings]");


::WorldParameters.MH.queue(">mod_msu", function() {
	::WorldParameters.Mod <- ::MSU.Class.Mod(::WorldParameters.ID, ::WorldParameters.Version, ::WorldParameters.Name);

	foreach (file in ::IO.enumerateFiles(::WorldParameters.ID + "/hooks")) {
		::include(file);
	}

	::WorldParameters.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/Enduriel/BB-World-Parameters");
	::WorldParameters.Mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);
	::WorldParameters.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.NexusMods, "https://www.nexusmods.com/battlebrothers/mods/732");


	local page = ::WorldParameters.Mod.ModSettings.addPage("General");

	local settings = [];

	settings.push(page.addRangeSetting("NumFactions", 3, 2, 9, 1, "Number of Factions"));
	settings.push(page.addRangeSetting("MinSouthern", 1, 0, 3, 1, "Minimum Southern City States"));
	settings.push(page.addRangeSetting("SettlementMinDistance", 12, 6, 18, 1, "Minimum Spacing Between Settlements"));
	settings.push(page.addRangeSetting("SouthernMinDistance", 24, 6, 36, 1, "Minimum Spacing Between Southern City States"));
	settings.push(page.addBooleanSetting("ForceLegendaryLocations", true, "Force Legendary Locations"))
	settings.push(page.addBooleanSetting("ForceCoastalSouthern", false, "Force Coastal City States"))


	local settlementsPage = ::WorldParameters.Mod.ModSettings.addPage("Settlement Multipliers");
	settings.push(settlementsPage.addRangeSetting("GlobalSettlementMult", 1.0, 0.0, 5.0, 0.1, "Settlement Count Multiplier"));
	settings.push(settlementsPage.addRangeSetting("LargeSettlementMult", 1.0, 0.0, 5.0, 0.1, "Large Settlement Multiplier"));
	settings.push(settlementsPage.addRangeSetting("MediumSettlementMult", 1.0, 0.0, 5.0, 0.1, "Medium Settlement Multiplier"));
	settings.push(settlementsPage.addRangeSetting("SmallSettlementMult", 1.0, 0.0, 5.0, 0.1, "Small Settlement Multiplier"));
	settings.push(settlementsPage.addRangeSetting("CoastalSettlementMult", 1.0, 0.0, 5.0, 0.1, "Coastal Settlement Multiplier"));
	settings.push(settlementsPage.addRangeSetting("CivilianSettlementMult", 1.0, 0.0, 5.0, 0.1, "Civilian Settlement Multiplier"));
	settings.push(settlementsPage.addRangeSetting("MilitarySettlementMult", 1.0, 0.0, 5.0, 0.1, "Military Settlement Multiplier"));

	foreach (setting in settings) {
		setting.Data.NewCampaign <- true;
		setting.Data.NewCampaignOnly <- true;
	}

	foreach (entry in ::Const.World.Settlements.CityStates) {
		local isSuitable = entry.isSuitable;
		entry.isSuitable = function (_terrain) {
			if (::WorldParameters.Mod.ModSettings.getSetting("ForceCoastalSouthern").getValue()) {
				if (_terrain.Adjacent[::Const.World.TerrainType.Shore] == 0 && _terrain.Adjacent[::Const.World.TerrainType.Ocean] == 0) {
					return false;
				}
			}
			return isSuitable(_terrain);
		}
	}
});
