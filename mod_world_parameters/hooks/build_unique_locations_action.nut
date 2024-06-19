::WorldParameters.MH.hook("scripts/factions/actions/build_unique_locations_action", function(q) {
	q.m.WorldParameters_UniqueBuildings <- [];
	q.m.WorldParameters_Looseness <- 0;

	foreach (key, value in q.m) {
		if (::MSU.String.startsWith(key, "Build")) {
			q.m.WorldParameters_UniqueBuildings.push(key);
		}
	}

	q.onExecute = @(__original) function( _faction ) {
		local countDone = 0;
		local newCountDone = 0;
		do {
			countDone = 0;
			foreach (key in this.m.WorldParameters_UniqueBuildings) {
				if (this.m[key] == false) {
					countDone++;
				}
			}
			__original(_faction);

			newCountDone = 0;
			foreach (key in this.m.WorldParameters_UniqueBuildings) {
				if (this.m[key] == false) {
					newCountDone++;
				}
			}
		}
		while (newCountDone != countDone && newCountDone != this.m.WorldParameters_UniqueBuildings.len() && this.WorldParameters_loosenRequirements())
		this.m.WorldParameters_Looseness = 0;
	}

	q.WorldParameters_loosenRequirements <- function() {
		if (!::WorldParameters.Mod.ModSettings.getSetting("ForceLegendaryLocations").getValue()) {
			return false;
		}
		if (this.m.WorldParameters_Looseness++ > 10) {
			::Hooks.error("Was not able to find a suitable location for a unique building even at max looseness, this honestly shouldn't be possible, but if this somehow happened for you, be aware that not all of your legendary locations have been generated");
			return false;
		}
		::logInfo("Increasing looseness to " + this.m.WorldParameters_Looseness + " to find a suitable location for a unique building");
		return true;
	}

	q.getTileToSpawnLocation = @(__original) function(_maxTries = 10, _notOnTerrain = [], _minDistToSettlements = 7, _maxDistToSettlements = 1000, _maxDistanceToAllies = 1000, _minDistToEnemyLocations = 7, _minDistToAlliedLocations = 7, _nearTile = null, _minY = 0.0, _maxY = 1.0) {
		_minDistToSettlements = ::Math.max(_minDistToSettlements - this.m.WorldParameters_Looseness, 1);
		_maxDistToSettlements += this.m.WorldParameters_Looseness * 5;
		_maxDistanceToAllies += this.m.WorldParameters_Looseness * 3;
		_minDistToEnemyLocations = ::Math.max(_minDistToEnemyLocations - this.m.WorldParameters_Looseness, 1);
		_minDistToAlliedLocations = ::Math.max(_minDistToAlliedLocations - this.m.WorldParameters_Looseness, 1);

		if (this.m.WorldParameters_Looseness >= 4) {
			for (local i = 3; i < this.m.WorldParameters_Looseness; ++i) {
				if (_notOnTerrain.len() < 1) {
					break;
				}
				local rand = ::Math.rand(0, _notOnTerrain.len() - 1);
				_notOnTerrain.remove(rand);
			}
		}

		if (this.m.WorldParameters_Looseness >= 8) {
			_minY = 0.0
			_maxY = 1.0
		}

		local tile = __original(_maxTries, _notOnTerrain, _minDistToSettlements, _maxDistToSettlements, _maxDistanceToAllies, _minDistToEnemyLocations, _minDistToAlliedLocations, _nearTile, _minY, _maxY);
		return tile;
	}
});
