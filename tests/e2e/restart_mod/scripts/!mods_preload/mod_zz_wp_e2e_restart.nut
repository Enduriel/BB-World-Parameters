// Test mod, never shipped: zipped by tests/e2e/build_restart_mod.sh as mod_zz_wp_e2e_restart.zip.
// Checks that a new campaign whose worldgen fails returns to the main menu with a message, leaves
// nothing behind, and that a second campaign then starts in the same session.
//
// It hooks world_state and main_menu_state and logs PROBE lines:
// - each world_state.init: whether it ended in the world or returned to the menu (ExitGame);
// - each world_state.onFinish: what the torn-down world left behind;
// - after a world state whose start failed has finished: the next step of setUpCycle() and a new
//   campaign with the same seed, the way the player would start one after the message (MSU's settings
//   page skipped, as the bb-game-probe harness does). The cycle:
//   1. the max settings (settings/max.nut): no room for the noble houses' fortresses, the specific message;
//   2. the default settings plus a settlement group whose script doesn't exist: an error World Parameters
//      doesn't predict, the generic message with the error text;
//   3. the default settings: a normal campaign;
// - 3 s into the world: whether it runs normally, then ::ClaudeProbe.done() when present.
// setUpCycle() applies step 1. The first campaign is started by restart_failed_worldgen.nut (original
// game, menu mode) or by world_fights itself (modern engine, --settings settings/restart_cycle.nut).

::WPE2E <- {
	Starts = 0,
	Seed = null,
	Rand = null,
	Next = [],
	BadGroup = null,

	function p( _key, _value ) {
		::logInfo("PROBE " + _key + " = " + _value);
	}

	function check( _key, _f ) {
		local v;
		try { v = _f(); } catch (e) { v = "ERROR: " + e; }
		this.p(_key, v);
	}

	function done() {
		this.p("restart test", "done");
		if ("ClaudeProbe" in ::getroottable()) ::ClaudeProbe.done();
	}

	function startCampaign( _seed ) {
		local menu = ::RootState.get("MainMenuState");
		if ("ModSettingsShown" in menu.m) menu.m.ModSettingsShown = true;
		// the same settings table new_campaign_menu_module.parseSettingsFromJS builds
		menu.campaign_menu_module_onStartPressed({
			Name = "Probe Company",
			Banner = ::Const.PlayerBanners[0],
			Difficulty = 1,
			EconomicDifficulty = 1,
			BudgetDifficulty = 1,
			Ironman = false,
			ExplorationMode = false,
			GreaterEvil = ::Const.World.GreaterEvilType.Random,
			PermanentDestruction = false,
			Seed = _seed,
			StartingScenario = "scenario.early_access"
		});
	}

	function setUpCycle() {
		local g = @(id, v) ::WorldParameters.Mod.ModSettings.getSetting(id).set(v, false, false);
		foreach (id in ["GlobalSettlementMult", "LargeSettlementMult", "MediumSettlementMult", "SmallSettlementMult", "CoastalSettlementMult", "CivilianSettlementMult", "MilitarySettlementMult"]) g(id, 5.0);
		g("NumFactions", 9); g("MinSouthern", 3); g("SettlementMinDistance", 6);
		g("SouthernMinDistance", 36); g("ForceCoastalSouthern", true);
		this.p("cycle step 1", "max settings");
		this.Next = [
			function() {
				::WPE2E.resetWorldParametersSettings();
				::WPE2E.BadGroup = { Amount = 1, List = [{ Script = "scripts/entity/world/settlements/wp_e2e_missing_settlement", isSuitable = @(_terrain) true }] };
				::Const.World.Settlements.Master.push(::WPE2E.BadGroup);
				::WPE2E.p("cycle step 2", "default settings and a settlement group with a missing script");
			},
			function() {
				local i = ::Const.World.Settlements.Master.find(::WPE2E.BadGroup);
				if (i != null) ::Const.World.Settlements.Master.remove(i);
				::WPE2E.p("cycle step 3", "default settings");
			}
		];
	}

	function resetWorldParametersSettings() {
		foreach (setting in ::WorldParameters.Mod.ModSettings.getAllElementsAsArray(@(_key, _e) "IsSetting" in _e.Data)) {
			setting.set(setting.BaseValue, false, false);
		}
	}
};

local mod = ::Hooks.register("mod_zz_wp_e2e_restart", "1.0.0", "World Parameters E2E restart test");
mod.require("mod_world_parameters", "mod_msu");
mod.queue(">mod_world_parameters", ">mod_msu", function() {
	::WPE2E.Rand = ::Math.rand;

	mod.hook("scripts/states/world_state", function(q) {
		q.init = @(__original) function() {
			local n = ++::WPE2E.Starts;
			if (this.m.CampaignSettings != null) ::WPE2E.Seed = this.m.CampaignSettings.Seed;
			try {
				__original();
			} catch (error) {
				::WPE2E.p("start " + n, "threw past World Parameters: " + error);
				throw error;
			}
			if (this.m.ExitGame) {
				::WPE2E.p("start " + n, "returned to the main menu");
				::WPE2E.check("start " + n + " globals restored", @() ::Const.World.Settlements.Master[3].Amount == 6 && ::Math.rand == ::WPE2E.Rand && ::Const.FactionArchetypes.len() == 3);
				::WPE2E.check("start " + n + " World Parameters failure message cleared", @() ::WorldParameters.WorldgenFailure == null);
				return;
			}
			::WPE2E.p("start " + n, "in the world");
			::WPE2E.check("start " + n + " settlements", @() ::World.EntityManager.getSettlements().len());
			::WPE2E.check("start " + n + " highest faction id", @() ::World.FactionManager.m.Factions.len() - 1);
			::WPE2E.check("start " + n + " player", @() ::World.State.getPlayer() != null);
			::Time.scheduleEvent(::TimeUnit.Real, 3000, function( _ ) {
				::WPE2E.check("world after 3s: loading screen visible", @() ::LoadingScreen.isVisible());
				::WPE2E.check("world after 3s: world state", @() ::RootState.get("WorldState") != null && ::World.State != null);
				::WPE2E.check("world after 3s: main menu visible", @() ::RootState.get("MainMenuState").isVisible());
				::WPE2E.check("world after 3s: days", @() ::World.getTime().Days);
				::WPE2E.done();
			}, null);
		}

		q.onFinish = @(__original) function() {
			__original();
			local n = ::WPE2E.Starts;
			::WPE2E.check("finish " + n + ": World.State", @() ::World.State);
			::WPE2E.check("finish " + n + ": EntityManager and FactionManager", @() "" + ::World.EntityManager + " " + ::World.FactionManager);
			::WPE2E.check("finish " + n + ": Stash global left", @() "Stash" in ::getroottable());
			::WPE2E.check("finish " + n + ": loading screen visible", @() ::LoadingScreen.isVisible());
			::WPE2E.check("finish " + n + ": main menu visible", @() ::RootState.get("MainMenuState").isVisible());
			::WPE2E.check("finish " + n + ": MSU popup visible", @() ::MSU.Popup.isVisible());
			if (this.m.ExitGame && ::WPE2E.Next.len() != 0) {
				::Time.scheduleEvent(::TimeUnit.Real, 1000, function( _ ) {
					::WPE2E.Next.remove(0)();
					::WPE2E.p("restart", "starting campaign " + (::WPE2E.Starts + 1));
					::WPE2E.startCampaign(::WPE2E.Seed);
				}, null);
			}
		}
	});

	mod.hook("scripts/states/main_menu_state", function(q) {
		q.onShow = @(__original) function() {
			__original();
			if (::WPE2E.Starts > 0) ::WPE2E.p("main menu shown after start " + ::WPE2E.Starts, "true");
		}
	});
});
