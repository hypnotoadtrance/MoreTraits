
local function ModOptionsConfig()
    local options = PZAPI.ModOptions:create("1299328280", "More Traits")

    options:addTitle("More Traits")
    options:addDescription("Changes made here are purely client-side.")
    options:addTickBox("ScroungerAnnounce", getText("UI_MoreTraits_Options_ScroungerAnnounce"), false, getText("UI_MoreTraits_Options_ScroungerAnnounce_ToolTip"))
    options:addTickBox("ScroungerHighlight", getText("UI_MoreTraits_Options_ScroungerHighlight"), true, getText("UI_MoreTraits_Options_ScroungerHighlight_ToolTip"))
    options:addComboBox("ScroungerHighlightTime", getText("UI_MoreTraits_Options_ScroungerHighlightTime"), getText("UI_MoreTraits_Options_ScroungerHighlightTime_ToolTip"))
    options:getOption("ScroungerHighlightTime"):addItem("10", false)
    options:getOption("ScroungerHighlightTime"):addItem("20", true)
    options:getOption("ScroungerHighlightTime"):addItem("30", false)
    options:getOption("ScroungerHighlightTime"):addItem("40", false)
    options:getOption("ScroungerHighlightTime"):addItem("50", false)
    options:getOption("ScroungerHighlightTime"):addItem("60", false)
    options:addTickBox("VagabondAnnounce", getText("UI_MoreTraits_Options_VagabondAnnounce"), false, getText("UI_MoreTraits_Options_VagabondAnnounce_ToolTip"))
    options:addTickBox("GraveRobberAnnounce", getText("UI_MoreTraits_Options_GraveRobberAnnounce"), false, getText("UI_MoreTraits_Options_GraveRobberAnnounce_ToolTip"))
    options:addTickBox("SuperImmuneAnnounce", getText("UI_MoreTraits_Options_SuperImmuneAnnounce"), false, getText("UI_MoreTraits_Options_SuperImmuneAnnounce_ToolTip"))
    options:addTickBox("GourmandAnnounce", getText("UI_MoreTraits_Options_GourmandAnnounce"), false, getText("UI_MoreTraits_Options_GourmandAnnounce_ToolTip"))
    options:addTickBox("AlbinoAnnounce", getText("UI_MoreTraits_Options_AlbinoAnnounce"), true, getText("UI_MoreTraits_Options_AlbinoAnnounce_ToolTip"))
    options:addTickBox("MartialDamage", getText("UI_MoreTraits_Options_MartialDamage"), false, getText("UI_MoreTraits_Options_MartialDamage_ToolTip"))
    options:addTickBox("HardyNotifier", getText("UI_MoreTraits_Options_HardyNotifier"), false, getText("UI_MoreTraits_Options_HardyNotifier_ToolTip"))
    options:addTickBox("DrinkNotifier", getText("UI_MoreTraits_Options_DrinkNotifier"), true, getText("UI_MoreTraits_Options_DrinkNotifier_ToolTip"))
    options:addTickBox("ProwessGunsAmmo", getText("UI_MoreTraits_Options_ProwessGunsAmmo"), true, getText("UI_MoreTraits_Options_ProwessGunsAmmo_ToolTip"))


end

ModOptionsConfig()