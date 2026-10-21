::WorldParameters.MH.hook("scripts/factions/faction_manager", function(q) {
	// These pick from arrays, not from MSU's WeightedContainer: that keys a table by its items, and Squirrel
	// orders table and array keys by memory address, so which archetype a roll picked changed from run to run
	// with the same seed. Every archetype has the same weight, so a uniform pick is the same distribution.
	q.WorldParameters_generateFewerFactions <- function( _archetypeLists, _numFactions ) {
		local remaining = clone _archetypeLists;
		local newArchetypeLists = [];
		for (local i = 0; i < _numFactions; ++i) {
			newArchetypeLists.push(remaining.remove(::Math.rand(0, remaining.len() - 1)));
		}
		return newArchetypeLists;
	}

	q.WorldParameters_generateMoreFactions <- function( _archetypeLists, _numFactions ) {
		local remaining = [];
		local newArchetypesFlattened = [];
		foreach (archetypeList in _archetypeLists) {
			local archetypes = clone archetypeList;
			// guarantee 1 from each list
			newArchetypesFlattened.push(archetypes.remove(::Math.rand(0, archetypes.len() - 1)));
			remaining.extend(archetypes);
		}

		for (local i = 0; i < (_numFactions - _archetypeLists.len()); ++i) {
			newArchetypesFlattened.push(remaining.remove(::Math.rand(0, remaining.len() - 1)));
		}

		local newArchetypesLists = newArchetypesFlattened.map(@(_archetype) [_archetype]);
		return newArchetypesLists;
	}

	q.createNobleHouses = @(__original) function() {
		local archetypeLists = ::Const.FactionArchetypes;
		local numFactions = ::WorldParameters.Mod.ModSettings.getSetting("NumFactions").getValue();
		if (numFactions < archetypeLists.len()) {
			::Const.FactionArchetypes = this.WorldParameters_generateFewerFactions(archetypeLists, numFactions);
		} else if (numFactions > archetypeLists.len()) {
			::Const.FactionArchetypes = this.WorldParameters_generateMoreFactions(archetypeLists, numFactions);
		}

		local ret;
		try {
			ret = __original();
		} catch (error) {
			::Const.FactionArchetypes = archetypeLists;
			throw error;
		}
		::Const.FactionArchetypes = archetypeLists;
		return ret;
	}

	q.createFactions = @(__original) function() {
		__original();
		local maxID = this.m.Factions.len() - 1;
		::logInfo("World Parameters: " + this.m.Factions.len() + " factions, the highest faction ID is " + maxID);
		if (maxID >= ::WorldParameters.MaxFactions) {
			::logWarning("World Parameters: the highest faction ID is " + maxID + ", which is " + ::WorldParameters.MaxFactions + " or more. In the original game, battles with a faction of ID " + ::WorldParameters.MaxFactions + " or more can break zones of control; the enemy factions have the highest IDs. Every village and noble house raises them, so use fewer to stay below " + ::WorldParameters.MaxFactions + ".");
		}
	}
})
