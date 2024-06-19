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
		::Const.World.Settlements.Master = settlementGroups;
		local ret = __original(_rect);
		this.WorldParameters_generateAdditionalSoutherns(__original, settlementGroups, _rect)

		::Const.World.Settlements.Master = oldSettlementGroups;
		return ret;
	}

	q.WorldParameters_generateAdditionalSoutherns <- function( _original, _settlementGroups, _rect ) {
		local southernGroups = _settlementGroups.filter(@(_, _g) _g.__Instance.isSouthern());
		::Const.World.Settlements.Master = southernGroups;
		for (local i = 0; i < 100; ++i) {
			if (this.WorldParameters_getNumSouthern() >= ::WorldParameters.Mod.ModSettings.getSetting("MinSouthern").getValue()) {
				break;
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
