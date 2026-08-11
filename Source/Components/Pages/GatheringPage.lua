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

-- Expansion names indexed by LE_EXPANSION_* + 1.
local EXPANSION_NAMES = { "Classic", "TBC", "WotLK", "Cataclysm" }

-- A row of mutually-exclusive radio buttons, one per expansion this addon
-- knows about (Functions_General:GetExpansionLevels), with the one matching
-- the realm's current expansion pre-selected. AceGUI has no dedicated
-- RadioGroup widget, so this is built from CheckBox widgets in "radio" mode
-- with manual exclusivity handling.
local function BuildExpansionRadioGroup()
    local currentLevel = Functions_General:GetServerExpansionLevel()
    local levels = Functions_General:GetExpansionLevels()

    local selected = 1
    for i, level in ipairs(levels) do
        if level == currentLevel then
            selected = i
            break
        end
    end

    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)
    group:SetAutoAdjustHeight(false)
    group:SetHeight(24)

    local buttons = {}
    for i, level in ipairs(levels) do
        local button = AceGUI:Create("CheckBox")
        button:SetType("radio")
        button:SetLabel(EXPANSION_NAMES[i] or ("Expansion " .. level))
        button:SetWidth(90)
        button:SetValue(i == selected)
        button:SetCallback("OnValueChanged", function(widget, _, checked)
            if checked then
                for j, other in ipairs(buttons) do
                    if j ~= i then
                        other:SetValue(false)
                    end
                end
            else
                -- Radio buttons shouldn't be deselectable by clicking the
                -- already-selected one - keep exactly one checked at all times.
                widget:SetValue(true)
            end
        end)
        buttons[i] = button
        group:AddChild(button)
    end

    return group
end

-- Adds the skill label + spacer + expansion radio group + spacer + DataTable
-- to `scroll`. `parent` is passed through to DataTable:Build unchanged (see
-- DataTable.lua).
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

    -- Spacer so the radio group doesn't sit flush against the label above it.
    -- A SimpleGroup rather than a Label: Label recomputes its own height
    -- from its FontString's text any time UpdateImageAnchor runs, which
    -- clobbers a manually set height. SimpleGroup only auto-resizes via
    -- LayoutFinished (summing its children's height), which SetAutoAdjustHeight
    -- disables outright, leaving our explicit height alone.
    local spacer = AceGUI:Create("SimpleGroup")
    spacer:SetAutoAdjustHeight(false)
    spacer:SetHeight(12)
    scroll:AddChild(spacer)

    scroll:AddChild(BuildExpansionRadioGroup())

    local spacer2 = AceGUI:Create("SimpleGroup")
    spacer2:SetAutoAdjustHeight(false)
    spacer2:SetHeight(12)
    scroll:AddChild(spacer2)

    local table = DataTable:Build(parent, data)
    scroll:AddChild(table)
end
