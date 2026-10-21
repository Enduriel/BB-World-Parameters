// ::WorldParameters.MH.hook("scripts/states/world_state", function(q) {
// 	q.startNewCampaign = @(__original) function() {
// 		local worldmap = ::MapGen.get("world.worldmap_generator");
// 		worldmap.m.MinX = ::WorldParameters.Mod.ModSettings.getSetting("SizeX").getValue();
// 		worldmap.m.MinY = ::WorldParameters.Mod.ModSettings.getSetting("SizeY").getValue();
// 		return __original();
// 	}
// });

::WorldParameters.MH.hook("scripts/states/world_state", function(q) {
	// When a new campaign's worldgen fails, vanilla leaves the loading screen up for good. Catch the error
	// instead, and leave the half-built world the way vanilla's exitGame does: the main menu shows again,
	// and once it is up it tells this state to finish, whose onFinish tears the world down.
	q.init = @(__original) function() {
		if (this.m.CampaignToLoadFileName != null) {
			return __original();
		}
		::WorldParameters.WorldgenFailure = null;
		try {
			__original();
		} catch (error) {
			this.WorldParameters_returnToMainMenu(error);
		}
	}

	q.WorldParameters_returnToMainMenu <- function( _error ) {
		local reason = ::WorldParameters.WorldgenFailure;
		::WorldParameters.WorldgenFailure = null;
		if (reason == null) {
			reason = "Generating the world failed with the error \"" + (typeof _error == "string" ? _error : typeof _error) + "\". If you raised World Parameters' settlement settings, lower them and try again.";
		}
		::logError("World Parameters: the new campaign couldn't be started, returning to the main menu. " + reason);
		::WorldParameters.Mod.Debug.addPopupMessage("The new campaign couldn't be started, so you are back in the main menu. " + reason, ::MSU.Popup.State.Full);
		this.m.ExitGame = true;
		this.WorldParameters_sendToMainMenu(0);
	}

	// The main menu state hid its screen when it added this state, and main_menu_screen.show() does nothing
	// while that screen still counts as visible, which it does until its hide animation has finished. So wait
	// for that before asking the main menu to show again (it then tells this state to finish).
	q.WorldParameters_sendToMainMenu <- function( _tries ) {
		local menu = ::RootState.get("MainMenuState");
		if (menu != null && menu.m.MainMenuScreen.isVisible() && _tries < 100) {
			::Time.scheduleEvent(::TimeUnit.Real, 100, this.WorldParameters_sendToMainMenu.bindenv(this), _tries + 1);
			return;
		}
		this.sendMessageToSiblings("AboutToFinish");
	}
});
