MoreTraits = MoreTraits or {};
MoreTraits.settings = MoreTraits.SETTINGS or {};

MoreTraits.settings.ScroungerAnnounce = false;
MoreTraits.settings.ScroungerHighlight = true;
MoreTraits.settings.ScroungerHighlightTime = 20;
MoreTraits.settings.GraveRobberAnnounce = false;
MoreTraits.settings.SuperImmuneAnnounce = false;
MoreTraits.settings.GourmandAnnounce = false;
MoreTraits.settings.AlbinoAnnounce = true;
MoreTraits.settings.MartialDamage = false;
MoreTraits.settings.VagabondAnnounce = false;
MoreTraits.settings.HardyNotifier = false;
MoreTraits.settings.DrinkNotifier = false;

if ModOptions and ModOptions.getInstance then
	local function onModOptionsApply(optionValues)
		MoreTraits.settings.ScroungerAnnounce = optionValues.settings.options.ScroungerAnnounce;
		MoreTraits.settings.ScroungerHighlight = optionValues.settings.options.ScroungerHighlight;
		MoreTraits.settings.ScroungerHighlightTime = optionValues.settings.options.ScroungerHighlightTime;
		MoreTraits.settings.GraveRobberAnnounce = optionValues.settings.options.GraveRobberAnnounce;
		MoreTraits.settings.SuperImmuneAnnounce = optionValues.settings.options.SuperImmuneAnnounce;
		MoreTraits.settings.GourmandAnnounce = optionValues.settings.options.GourmandAnnounce;
		MoreTraits.settings.AlbinoAnnounce = optionValues.settings.options.AlbinoAnnounce;
		MoreTraits.settings.MartialDamage = optionValues.settings.options.MartialDamage;
		MoreTraits.settings.VagabondAnnounce = optionValues.settings.options.VagabondAnnounce;
		MoreTraits.settings.HardyNotifier = optionValues.settings.options.HardyNotifier;
		MoreTraits.settings.DrinkNotifier = optionValues.settings.options.DrinkNotifier;
	end
	local SETTINGS = {
		options_data = {
			ScroungerAnnounce = {
				name = "UI_MoreTraits_Options_ScroungerAnnounce",
				tooltip = "UI_MoreTraits_Options_ScroungerAnnounce_ToolTip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			ScroungerHighlight = {
				name = "UI_MoreTraits_Options_ScroungerHighlight",
				tooltip = "UI_MoreTraits_Options_ScroungerHighlight_ToolTip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			ScroungerHighlightTime = {
				"10", "20", "30", "40", "50", "60",
				name = "UI_MoreTraits_Options_ScroungerHighlightTime",
				tooltip = "UI_MoreTraits_Options_ScroungerHighlightTime_ToolTip",
				default = 2,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			VagabondAnnounce = {
				name = "UI_MoreTraits_Options_VagabondAnnounce",
				tooltip = "UI_MoreTraits_Options_VagabondAnnounce_ToolTip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			GraveRobberAnnounce = {
				name = "UI_MoreTraits_Options_GraveRobberAnnounce",
				tooltip = "UI_MoreTraits_Options_GraveRobberAnnounce_ToolTip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			SuperImmuneAnnounce = {
				name = "UI_MoreTraits_Options_SuperImmuneAnnounce",
				tooltip = "UI_MoreTraits_Options_SuperImmuneAnnounce_ToolTip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			GourmandAnnounce = {
				name = "UI_MoreTraits_Options_GourmandAnnounce",
				tooltip = "UI_MoreTraits_Options_GourmandAnnounce_ToolTip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			AlbinoAnnounce = {
				name = "UI_MoreTraits_Options_AlbinoAnnounce",
				tooltip = "UI_MoreTraits_Options_AlbinoAnnounce_ToolTip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			MartialDamage = {
				name = "UI_MoreTraits_Options_MartialDamage",
				tooltip = "UI_MoreTraits_Options_MartialDamage_ToolTip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			HardyNotifier = {
				name = "UI_MoreTraits_Options_HardyNotifier",
				tooltip = "UI_MoreTraits_Options_HardyNotifier_ToolTip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			DrinkNotifier = {
				name = "UI_MoreTraits_Options_DrinkNotifier",
				tooltip = "UI_MoreTraits_Options_DrinkNotifier_ToolTip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			ProwessGunsAmmo = {
				name = "UI_MoreTraits_Options_ProwessGunsAmmo",
				tooltip = "UI_MoreTraits_Options_ProwessGunsAmmo_ToolTip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
		},
		mod_id = 'ToadTraits',
		mod_shortname = 'More Traits',
		mod_fullname = 'More Traits',
	}
	ModOptions:getInstance(SETTINGS)
	ModOptions:loadFile()

	Events.OnPreMapLoad.Add(function()
		onModOptionsApply({ settings = SETTINGS })
	end)
end