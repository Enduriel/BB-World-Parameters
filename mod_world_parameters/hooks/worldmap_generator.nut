::WorldParameters.MH.hook("scripts/mapgen/templates/world/worldmap_generator", function(q) {
	q.WorldParameters_multSettlementGroupAmount <- function( _settlementGroup ) {
		local allCoastal = true;
		_settlementGroup.WorldParameters_BaseAmount <- _settlementGroup.Amount;

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

		local maxAmount = _settlementGroup.WorldParameters_BaseAmount * ::WorldParameters.MaxCombinedMult;
		if (_settlementGroup.Amount > maxAmount + 0.001) {
			::logWarning("World Parameters: the settlement multipliers combine to x" + (_settlementGroup.Amount / _settlementGroup.WorldParameters_BaseAmount) + " for " + ::IO.scriptFilenameByHash(_settlementGroup.__Instance.ClassNameHash) + " and similar settlements, capping it at x" + ::WorldParameters.MaxCombinedMult);
			_settlementGroup.Amount = maxAmount;
		}
	}

	// faction_manager gives every civilian settlement its own faction, created after the arena and before the
	// city states, noble houses and enemy factions, so each civilian settlement raises all of their IDs.
	// Count the other factions the way faction_manager creates them.
	q.WorldParameters_getMaxCivilianSettlements <- function() {
		local numOtherFactions = 3 + 1; // three reserved slots, the generic enemy
		if (::Const.DLC.Desert) {
			numOtherFactions += 1 + ::Const.CityStateArchetypes.len() + 1; // the arena, the city states, the nomads
		}
		numOtherFactions += ::WorldParameters.Mod.ModSettings.getSetting("NumFactions").getValue(); // noble houses
		numOtherFactions += 1 + (::Const.DLC.Wildmen ? 1 : 0) + 4; // bandits, barbarians, orcs, goblins, undead, zombies
		return ::WorldParameters.MaxFactions - numOtherFactions;
	}

	q.WorldParameters_capCivilianSettlements <- function( _settlementGroups ) {
		local civilianGroups = _settlementGroups.filter(@(_, _g) !_g.__Instance.isMilitary() && !_g.__Instance.isSouthern());
		local numCivilian = 0;
		foreach (settlementGroup in civilianGroups) {
			numCivilian += settlementGroup.Amount;
		}
		local maxCivilian = this.WorldParameters_getMaxCivilianSettlements();
		if (numCivilian <= maxCivilian) {
			return;
		}

		::logWarning("World Parameters: the settings ask for " + numCivilian + " villages, but more than " + maxCivilian + " would give factions an ID of " + ::WorldParameters.MaxFactions + " or more, which breaks battles. Generating at most " + maxCivilian + " villages.");
		// take villages from the group furthest above its vanilla amount, to keep the proportions the settings ask for
		for (; numCivilian > maxCivilian; --numCivilian) {
			local largest = null;
			local largestRatio = 0.0;
			foreach (settlementGroup in civilianGroups) {
				local ratio = settlementGroup.Amount * 1.0 / ::Math.max(1, settlementGroup.WorldParameters_BaseAmount);
				if (settlementGroup.Amount > 0 && (largest == null || ratio > largestRatio)) {
					largest = settlementGroup;
					largestRatio = ratio;
				}
			}
			--largest.Amount;
		}
	}

	q.buildSettlements = @(__original) function( _rect ) {
		local oldSettlementGroups = ::Const.World.Settlements.Master;
		local settlementGroups = ::MSU.deepClone(oldSettlementGroups);

		local extraContainer = ::MSU.Class.WeightedContainer();
		local total = 0.0; // weighted container should probably have getTotal be public
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
			extraContainer.add(settlementGroup, remainingAmount);
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

		extraContainer.add(0, ::Math.ceil(total) - total);

		for (local i = 0; i < total; ++i) {
			local roll = extraContainer.roll();
			extraContainer.remove(roll);
			if (roll != 0) {
				roll.Amount += 1;
			}
		}
		this.WorldParameters_capCivilianSettlements(settlementGroups);
		::Const.World.Settlements.Master = settlementGroups;
		local ret = __original(_rect);
		this.WorldParameters_generateAdditionalSoutherns(__original, settlementGroups, _rect)

		::Const.World.Settlements.Master = oldSettlementGroups;
		return ret;
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
			_original(_rect);
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
		__original(_rect);
		::Math.rand = rand;
	}
});
