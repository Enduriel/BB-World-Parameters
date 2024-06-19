::WorldParameters.MH.hook("scripts/factions/faction_manager", function(q) {
	q.WorldParameters_generateFewerFactions <- function( _archetypeLists, _numFactions ) {
		local weightedContainer = ::MSU.Class.WeightedContainer();
		weightedContainer.addMany(1, _archetypeLists);
		local newArchetypeLists = [];
		for (local i = 0; i < _numFactions; ++i) {
			local roll = weightedContainer.roll();
			weightedContainer.remove(roll);
			newArchetypeLists.push(roll);
		}
		return newArchetypeLists;
	}

	q.WorldParameters_generateMoreFactions <- function( _archetypeLists, _numFactions ) {
		local weightedContainers = [];
		local newArchetypesFlattened = [];
		foreach (archetypeList in _archetypeLists) {
			local weightedContainer = ::MSU.Class.WeightedContainer();
			weightedContainer.addMany(1, archetypeList);
			weightedContainers.push(weightedContainer);
			// guarantee 1 from each list
			local roll = weightedContainer.roll();
			weightedContainer.remove(roll);
			newArchetypesFlattened.push(roll);
		}

		local mergedContainer = ::MSU.Class.WeightedContainer();
		foreach (weightedContainer in weightedContainers) {
			mergedContainer.merge(weightedContainer);
		}

		for (local i = 0; i < (_numFactions - _archetypeLists.len()); ++i) {
			local roll = mergedContainer.roll()
			mergedContainer.remove(roll);
			newArchetypesFlattened.push(roll);
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

		local ret = __original();
		::Const.FactionArchetypes = archetypeLists;
		return ret;
	}
})
