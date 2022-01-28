MoreTraits = MoreTraits or {};
MoreTraits.settings = MoreTraits.SETTINGS or {};

MoreTraits.settings.ScroungerAnnounce = false;
MoreTraits.settings.ScroungerHighlight = true;
MoreTraits.settings.ScroungerHighlightTime = 20;

if ModOptions and ModOptions.getInstance then
    local function onModOptionsApply(optionValues)
        MoreTraits.settings.ScroungerAnnounce = optionValues.settings.options.ScroungerAnnounce;
        MoreTraits.settings.ScroungerHighlight = optionValues.settings.options.ScroungerHighlight;
        MoreTraits.settings.ScroungerHighlightTime = optionValues.settings.options.ScroungerHighlightTime;
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