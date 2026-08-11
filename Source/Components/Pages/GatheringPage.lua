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

-- A row of mutually-exclusive radio buttons, one per expansion this addon
-- knows about (Functions_General:GetExpansionLevels), with the one matching
-- the realm's current expansion pre-selected. AceGUI has no dedicated
-- RadioGroup widget, so this is built from CheckBox widgets in "radio" mode
-- with manual exclusivity handling. `onSelect(level)` fires whenever the user
-- picks a different button (not for the initial pre-selection - the caller
-- already gets that back as the second return value).
-- Returns the group widget and the initially selected level.
local function BuildExpansionRadioGroup(onSelect)
    local currentLevel = Functions_General:GetServerExpansionLevel()

    -- MiningData/HerbalismData only have columns for Classic and TBC so far,
    -- so higher levels wouldn't have anything to show - drop them until data
    -- for them exists.
    local levels = {}
    for _, level in ipairs(Functions_General:GetExpansionLevels()) do
        if level <= LE_EXPANSION_BURNING_CRUSADE then
            levels[#levels + 1] = level
        end
    end

    local selected = 1
    for i, level in ipairs(levels) do
        if level == currentLevel then
            selected = i
            break
        end
    end

    -- Sized to its own known content (label width + button count * button
    -- width) rather than SetFullWidth(true): at this point `scroll` (this
    -- group's eventual parent) hasn't been given its real width yet - that
    -- only happens later, when the outer tab group's Fill layout runs after
    -- Mining/Herbalism's Build call already returns - so the "Flow" layout
    -- below would size itself off whatever stale width this recycled
    -- ScrollFrame widget happened to have from its last, unrelated use,
    -- wrapping the buttons onto multiple rows whenever that stale width was
    -- too narrow.
    local BUTTON_WIDTH = 90
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetAutoAdjustHeight(false)
    group:SetHeight(24)

    -- AceGUI has no dedicated RadioGroup widget with a built-in label slot,
    -- so this Label is just the first child in the Flow row, rendering to
    -- the left of the buttons within the same group. Font matches the
    -- CheckBox labels' GameFontHighlight (Label defaults to the smaller
    -- GameFontHighlightSmall), and its width is the text's actual measured
    -- width plus a little padding rather than a guessed fixed number -
    -- guessing came up a few pixels short and wrapped the second button
    -- onto its own row.
    local label = AceGUI:Create("Label")
    label:SetFontObject(GameFontHighlight)
    label:SetText("Current Expansion Data:")
    local labelWidth = math.ceil(label.label:GetStringWidth()) + 8
    label:SetWidth(labelWidth)
    -- Flow layout vertically aligns row children using each child's own
    -- alignoffset (default: half its frame height). CheckBox always ends up
    -- 24px tall (its OnAcquire calls SetDescription(nil), whose else-branch
    -- is SetHeight(24)), but Label sizes itself off its FontString's actual
    -- text height, which is shorter - mismatched alignoffsets, so the label
    -- text sat higher than the button labels. Matching CheckBox's height
    -- here (after the width/font/text calls above, so nothing recomputes it
    -- afterward) makes both default to the same alignoffset.
    label:SetHeight(24)

    group:SetWidth(labelWidth + BUTTON_WIDTH * #levels)
    group:AddChild(label)

    local buttons = {}
    for i, level in ipairs(levels) do
        local button = AceGUI:Create("CheckBox")
        button:SetType("radio")
        button:SetLabel(Functions_General:GetExpansionName(level))
        button:SetWidth(BUTTON_WIDTH)
        button:SetValue(i == selected)
        button:SetCallback("OnValueChanged", function(widget, _, checked)
            if checked then
                for j, other in ipairs(buttons) do
                    if j ~= i then
                        other:SetValue(false)
                    end
                end
                onSelect(level)
            else
                -- Radio buttons shouldn't be deselectable by clicking the
                -- already-selected one - keep exactly one checked at all times.
                widget:SetValue(true)
            end
        end)
        buttons[i] = button
        group:AddChild(button)
    end

    return group, levels[selected]
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
            skillText = skillText .. " You should go train!"
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

    -- Replaced in place (see RebuildTable) whenever the radio group's
    -- selected expansion changes, rather than rebuilding the whole page.
    local tableWidget

    local function RebuildTable(selectedExpansion)
        if tableWidget then
            for idx, child in ipairs(scroll.children) do
                if child == tableWidget then
                    table.remove(scroll.children, idx)
                    break
                end
            end
            AceGUI:Release(tableWidget)
        end
        tableWidget = DataTable:Build(parent, data, selectedExpansion)
        scroll:AddChild(tableWidget)
    end

    local radioGroup, initialExpansion = BuildExpansionRadioGroup(RebuildTable)
    scroll:AddChild(radioGroup)

    local spacer2 = AceGUI:Create("SimpleGroup")
    spacer2:SetAutoAdjustHeight(false)
    spacer2:SetHeight(12)
    scroll:AddChild(spacer2)

    RebuildTable(initialExpansion)
end
