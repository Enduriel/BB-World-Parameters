::WorldParameters.MH.hook("scripts/mapgen/templates/world/worldmap_generator", function(q) {
	q.WorldParameters_multSettlementGroupAmount <- function( _settlementGroup ) {
		local allCoastal = true;

		foreach (settlementEntry in _settlementGroup.List) {
			if (!("IsCoastal" in settlementEntry) || !settlementEntry.IsCoastal) {
				allCoastal = false;
			}
			_settlementGroup.__Instance <- ::new(settlementEntry.Script);
		}
		if (_settlementGroup.__Instance.isSouthern()) {
			return;
		}

		_settlementGroup.Amount *= ::WorldParameters.Mod.ModSettings.getSetting("GlobalSettlementMult").getValue();

		if (allCoastal) {
			_settlementGroup.Amount *= ::WorldParameters.Mod.ModSettings.getSetting("CoastalSettlementMult").getValue();
		}
		switch (_settlementGroup.__Instance.getSize()) {
			case 1:
				_settlementGroup.Amount *= ::WorldParameters.Mod.ModSettings.getSetting("SmallSettlementMult").getValue();
				break;
			case 2:
				_settlementGroup.Amount *= ::WorldParameters.Mod.ModSettings.getSetting("MediumSettlementMult").getValue();
				break;
			case 3:
				_settlementGroup.Amount *= ::WorldParameters.Mod.ModSettings.getSetting("LargeSettlementMult").getValue();
				break;
		}

		if (_settlementGroup.__Instance.isMilitary()) {
			_settlementGroup.Amount *= ::WorldParameters.Mod.ModSettings.getSetting("MilitarySettlementMult").getValue();
		} else {
			_settlementGroup.Amount *= ::WorldParameters.Mod.ModSettings.getSetting("CivilianSettlementMult").getValue();
		}
	}

	q.buildSettlements = @(__original) function( _rect ) {
		local oldSettlementGroups = ::Const.World.Settlements.Master;
		local settlementGroups = ::MSU.deepClone(oldSettlementGroups);

		// [settlement group or null, weight] in the groups' order. Not MSU's WeightedContainer: that keys a table
		// by its items, and Squirrel orders table keys by memory address, so the extra settlements went to
		// different groups from run to run with the same seed.
		local extras = [];
		local total = 0.0;
		local militaries = [];
		local numMilitary = 0;
		foreach (settlementGroup in settlementGroups) {
			this.WorldParameters_multSettlementGroupAmount(settlementGroup);
			if (settlementGroup.__Instance.isMilitary()) {
				numMilitary += settlementGroup.Amount;
				militaries.push(settlementGroup);
			}

			if (!("AdditionalSpace" in settlementGroup)) {
				settlementGroup.AdditionalSpace <- 0;
			}
			if (settlementGroup.__Instance.isSouthern()) {
				settlementGroup.AdditionalSpace += ::WorldParameters.Mod.ModSettings.getSetting("SouthernMinDistance").getValue() - 12;
			} else {
				settlementGroup.AdditionalSpace += ::WorldParameters.Mod.ModSettings.getSetting("SettlementMinDistance").getValue() - 12;
			}

			local remainingAmount = settlementGroup.Amount - ::Math.floor(settlementGroup.Amount);
			extras.push([settlementGroup, remainingAmount]);
			total += remainingAmount;
			settlementGroup.Amount = ::Math.floor(settlementGroup.Amount);
			// if (::WorldParameters.Mod.ModSettings.getSetting("ForceCoastalSouthern").getValue() && settlementGroup.__Instance.isSouthern()) {
			// 	foreach (settlementEntry in settlementGroup.List) {
			// 		if ("IsFlexible" in settlementEntry) {
			// 			delete settlementEntry.IsFlexible;
			// 		}
			// 		settlementEntry.IsCoastal <- true;
			// 	}
			// }
		}

		local numFactions = ::WorldParameters.Mod.ModSettings.getSetting("NumFactions").getValue();
		if (numMilitary < numFactions) {
			::logWarning("Not enough military settlements (" + numMilitary + ") for the number of factions (" + numFactions + "). Adding more.");
			for (local i = 0; i < (numFactions - numMilitary); ++i) {
				militaries[i % militaries.len()].Amount += 1;
			}
		}

		extras.push([null, ::Math.ceil(total) - total]);

		for (local i = 0; i < total; ++i) {
			local index = ::WorldParameters.rollWeightedIndex(extras);
			local settlementGroup = extras.remove(index)[0];
			if (settlementGroup != null) {
				settlementGroup.Amount += 1;
			}
		}
		::Const.World.Settlements.Master = settlementGroups;
		local ret;
		try {
			ret = __original(_rect);
			this.WorldParameters_generateAdditionalSoutherns(__original, settlementGroups, _rect)
		} catch (error) {
			::Const.World.Settlements.Master = oldSettlementGroups;
			throw error;
		}

		::Const.World.Settlements.Master = oldSettlementGroups;
		this.WorldParameters_checkNobleHouseFortresses();
		return ret;
	}

	// faction_manager.assignSettlementsToNobleHouses gives each noble house a military settlement as its
	// fortress and throws when there are too few. Villages are placed before military settlements, so with
	// many villages and little spacing the map can be full before every noble house has one.
	q.WorldParameters_checkNobleHouseFortresses <- function() {
		local numNobleHouses = ::WorldParameters.Mod.ModSettings.getSetting("NumFactions").getValue();
		local numMilitary = ::World.EntityManager.getSettlements().filter(@(_, _s) _s.isMilitary()).len();
		if (numMilitary < numNobleHouses) {
			::WorldParameters.failWorldgen(format("There is no room left for the noble houses' fortresses: each of the %i noble houses needs a military settlement, but only %i fit on the map, because the settlements placed before them (villages first) filled it. Lower the settlement multipliers, above all for villages, lower the Minimum Spacing Between Settlements, or choose fewer factions.", numNobleHouses, numMilitary));
		}
	}

	q.WorldParameters_generateAdditionalSoutherns <- function( _original, _settlementGroups, _rect ) {
		local southernGroups = _settlementGroups.filter(@(_, _g) _g.__Instance.isSouthern());
		::Const.World.Settlements.Master = southernGroups;
		local minSouthern = ::WorldParameters.Mod.ModSettings.getSetting("MinSouthern").getValue();
		local numSouthern;
		for (local i = 0; i < 100; ++i) {
			numSouthern = this.WorldParameters_getNumSouthern();
			if (numSouthern >= minSouthern) {
				break;
			}
			// place only the missing city states: there are only three city state factions and three
			// city state names, and vanilla never finishes naming a fourth city state
			foreach (southernGroup in southernGroups) {
				southernGroup.Amount = minSouthern - numSouthern;
			}
			local rand = ::Math.rand;
			local climbNext = false;
			::Math.rand = function(_min, _max) {
				if (climbNext) {
					::getstackinfos(2).locals.settlementTiles.extend(
						::World.EntityManager.getSettlements().map(@(_s) _s.getTile())
					)
					::Math.rand = rand;
				}
				if (_min == 0 && _max == 1) {
					climbNext = true;
				}
				return rand(_min, _max);
			}
			try {
				_original(_rect);
			} catch (error) {
				::Math.rand = rand;
				throw error;
			}
		}
		numSouthern = this.WorldParameters_getNumSouthern();
		if (numSouthern < minSouthern) {
			::logWarning("World Parameters: placed only " + numSouthern + " of the minimum " + minSouthern + " southern city states; lower the southern city state spacing to fit more");
		}
	}

	q.WorldParameters_getNumSouthern <- function() {
		local numSouthern = 0;
		local settlements = ::World.EntityManager.getSettlements();
		foreach (settlement in settlements) {
			if (settlement.isSouthern()) {
				++numSouthern;
			}
		}
		return numSouthern;
	}

	// vanilla's guaranteeAllBuildingsInSettlements picks from an empty candidate list and throws when a building
	// exists fewer than twice and no other settlement can take it, which aborts the campaign start.
	// Mark such buildings as present for the call, so vanilla skips them, then restore the counts.
	q.guaranteeAllBuildingsInSettlements = @(__original) function() {
		local settlements = ::World.EntityManager.getSettlements();
		local buildings = [
			{ Counter = "Fletchers", ID = "building.fletcher", isCandidate = @(_s) _s.getSize() >= 2 },
			{ Counter = "Temples", ID = "building.temple", isCandidate = @(_s) _s.getSize() >= 2 },
			{ Counter = "Barbers", ID = "building.barber", isCandidate = @(_s) _s.getSize() >= 2 && !_s.isMilitary() },
			{ Counter = "Kennels", ID = "building.kennel", isCandidate = @(_s) _s.isMilitary() },
			{ Counter = "Taxidermists", ID = "building.taxidermist", isCandidate = @(_s) !_s.isMilitary() }
		];
		local skipped = {};
		foreach (building in buildings) {
			local count = ::Const.World.Buildings[building.Counter];
			if (count >= 2 || (building.Counter == "Taxidermists" && !::Const.DLC.Unhold)) {
				continue;
			}
			local hasCandidate = false;
			foreach (settlement in settlements) {
				if (building.isCandidate(settlement) && settlement.hasFreeBuildingSlot() && !settlement.hasBuilding(building.ID)) {
					hasCandidate = true;
					break;
				}
			}
			if (!hasCandidate) {
				::logWarning("World Parameters: no settlement has room for another " + building.ID + " (" + count + " placed), skipping it");
				skipped[building.Counter] <- count;
				::Const.World.Buildings[building.Counter] = 2;
			}
		}

		__original();
		foreach (counter, count in skipped) {
			::Const.World.Buildings[counter] = count;
		}
	}

	q.buildLandAndSea = @(__original) function( _rect ) {
		local rand = ::Math.rand;
		local count = 0;
		if (::WorldParameters.Mod.ModSettings.getSetting("ForceCoastalSouthern").getValue()) {
			::Math.rand = function(_min, _max) {
				if (_min == 0 && _max == 1) {
					if (++count % 4 == 0) {
						return 1;
					}
					return rand(_min, _max);
				} else {
					::Math.rand = rand;
					return rand(_min, _max);
				}
			}
		}
		try {
			__original(_rect);
		} catch (error) {
			::Math.rand = rand;
			throw error;
		}
		::Math.rand = rand;
	}
});
