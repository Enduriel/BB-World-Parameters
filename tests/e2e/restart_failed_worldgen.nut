// Runs the cycle in restart_mod/.../mod_zz_wp_e2e_restart.nut: a new campaign whose worldgen can't complete returns to the main menu with a message, and the next
// campaign starts in the same session (the max settings: every multiplier x5, spacing 6, 9 noble houses
// leave no room for the noble houses' fortresses, which made vanilla throw in
// assignSettlementsToNobleHouses and leave the loading screen up).
//
// Original game, menu mode, with the test mod (build_restart_mod.sh):
//   run_probe.py restart_failed_worldgen.nut --mode menu --with-mod held:mod_msu \
//     --with-mod <world_parameters zip> --with-mod <scratch>/mod_zz_wp_e2e_restart.zip --timeout 900
// Modern engine: world_fights --settings settings/restart_cycle.nut --extra <wp zip>,<test mod zip> --days 1
// (world_fights starts the first campaign itself; this file isn't used there).
//
// Passing run:
//   PROBE start 1 = returned to the main menu
//   PROBE start 1 globals restored = true
//   PROBE main menu shown after start 1 = true
//   PROBE finish 1: World.State = null, EntityManager and FactionManager = null null,
//     Stash global left = false, loading screen visible = false, main menu visible = true
//   PROBE start 2 = returned to the main menu, with the same finish 2 lines
//   PROBE start 3 = in the world, PROBE start 3 player = true
//   PROBE world after 3s: loading screen visible = false, world state = true, main menu visible = false
//   PROBE restart test = done
// and the log has "World Parameters: the new campaign couldn't be started, returning to the main menu.
// There is no room left for the noble houses' fortresses ..." for start 1 and "... Generating the world
// failed with the error ..." (the missing script) for start 2.

::ClaudeProbe.DeferDone = true;
::WPE2E.setUpCycle();
::WPE2E.startCampaign("VUQJTMOOMN");
