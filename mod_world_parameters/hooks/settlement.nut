::WorldParameters.MH.hook("scripts/entity/world/settlement", function(q) {
	// Vanilla draws names until it finds one no settlement has yet, with no limit on the tries,
	// so it never returns once every name in a settlement type's list (19 to 40 names) is taken.
	// While a name is free, vanilla runs unchanged, so maps that generate today stay the same.
	q.getRandomName = @(__original) function( _names ) {
		local taken = {};
		foreach (settlement in ::World.EntityManager.getSettlements()) {
			taken[settlement.getName()] <- true;
		}
		foreach (name in _names) {
			if (!(name in taken)) {
				return __original(_names);
			}
		}

		local baseName = _names[::Math.rand(0, _names.len() - 1)];
		for (local i = 2; ; ++i) {
			local name = baseName + " " + ::WorldParameters.toRomanNumeral(i);
			if (!(name in taken)) {
				::logWarning("World Parameters: every name for " + ::IO.scriptFilenameByHash(this.ClassNameHash) + " is taken, naming this settlement " + name);
				return name;
			}
		}
	}
});
