::ModWorldParameters <- {
	ID = "mod_world_parameters",
	Name = "ModWorldParameters",
	Version = "0.0.0"
}
::ModWorldParameters.HooksMod <- ::Hooks.register(::ModWorldParameters.ID, ::ModWorldParameters.Version, ::ModWorldParameters.Name);
::ModWorldParameters.HooksMod.require("mod_msu");
::ModWorldParameters.HooksMod.queue(">mod_msu", function()
{
	::ModWorldParameters.Mod <- ::MSU.Class.Mod(::ModWorldParameters.ID, ::ModWorldParameters.Version, ::ModWorldParameters.Name);
});