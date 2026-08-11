--[[-----------------------------------------------------------------------------
GatheringPage
Shared header for gathering-profession pages (Mining, Herbalism, Skinning):
the current-skill label (colored red via GetProfessionShouldGoLearn), a spacer,
and the profession's DataTable. Scoped to gathering specifically - crafting
professions don't share this shape and should get their own builder.

Callers create their own ScrollFrame, call AddHeader to populate the shared
part, then keep adding profession-specific widgets (e.g. a "Recommended gear"
section) before returning the scroll.
-------------------------------------------------------------------------------]]
local AceGUI = LibStub("AceGUI-3.0")

GatheringPage = {}

-- Adds the skill label + spacer + DataTable to `scroll`. `parent` is passed
-- through to DataTable:Build unchanged (see DataTable.lua).
function GatheringPage:AddHeader(scroll, parent, profession, data)
    local skillLbl = AceGUI:Create("Label")
    skillLbl:SetFullWidth(true)
    skillLbl:SetFontObject(GameFontHighlightLarge)

    local skill = Functions_Professions:GetProfessionSkillNumber(profession)
    local maxSkill = Functions_Professions:GetProfessionMaxSkillNumber(profession)

    local skillText = "Current " .. profession .. " Skill: "
    if skill then
        skillText = skillText .. skill .. "/" .. maxSkill

        local shouldGoTrain = Functions_Professions:GetProfessionShouldGoLearn(skill, maxSkill, profession)
        if (shouldGoTrain) then
            skillText = skillText .. " You should go train soon!"
            skillLbl:SetColor(1, 0, 0)
        else
            skillLbl:SetColor()
        end
    else
        skillText = skillText .. "N/A"
        skillLbl:SetColor()
    end
    skillLbl:SetText(skillText)
    scroll:AddChild(skillLbl)

    -- Spacer so the table doesn't sit flush against the label above it.
    -- A SimpleGroup rather than a Label: Label recomputes its own height
    -- from its FontString's text any time UpdateImageAnchor runs, which
    -- clobbers a manually set height. SimpleGroup only auto-resizes via
    -- LayoutFinished (summing its children's height), which SetAutoAdjustHeight
    -- disables outright, leaving our explicit height alone.
    local spacer = AceGUI:Create("SimpleGroup")
    spacer:SetAutoAdjustHeight(false)
    spacer:SetHeight(12)
    scroll:AddChild(spacer)

    local table = DataTable:Build(parent, data)
    scroll:AddChild(table)
end
