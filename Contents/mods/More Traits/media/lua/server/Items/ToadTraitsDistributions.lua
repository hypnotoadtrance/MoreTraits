require "Items/Distributions"
require "Items/ProceduralDistributions"

local i;
-- Distributions for ProceduralDistributions.lua
local myDistTable = {
    "MoreTraits.MedicalMag1", 0.1,
    "MoreTraits.MedicalMag2", 0.1,
    "MoreTraits.MedicalMag3", 0.1,
    "MoreTraits.MedicalMag4", 0.1,
    "MoreTraits.AntiqueMag1", 0.1,
    "MoreTraits.AntiqueMag2", 0.1,
    "MoreTraits.AntiqueMag3", 0.1,
}
local function insertTable(t1, t2)
    local n = #t1
    for i = 1, #t2 do
        t1[n + i] = t2[i]
    end
end

insertTable(ProceduralDistributions["list"]["BookstoreBooks"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["MagazineRackMixed"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["PostOfficeMagazines"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["PostOfficeBooks"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["PostOfficeNewspapers"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["CrateNewspapers"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["MagazineRackMaps"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["MagazineRackMixed"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["GunStoreMagazineRack"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["CrateMagazines"].items, myDistTable)
insertTable(ProceduralDistributions["list"]["LibraryBooks"].items, myDistTable)