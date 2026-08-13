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

-- Vertical gap between header sections. A SimpleGroup rather than a Label:
-- Label recomputes its own height from its FontString's text any time
-- UpdateImageAnchor runs, which clobbers a manually set height. SimpleGroup
-- only auto-resizes via LayoutFinished (summing its children's height),
-- which SetAutoAdjustHeight disables outright, leaving our explicit height
-- alone. Returns the widget rather than adding it itself, since RebuildTable
-- below needs to hang onto one instance as an insertion anchor.
local function BuildSpacer()
    local spacer = AceGUI:Create("SimpleGroup")
    spacer:SetAutoAdjustHeight(false)
    spacer:SetHeight(12)
    return spacer
end

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
    label:SetFontObject(GameFontHighlightLarge)
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

-- A Label showing `text`, with tooltip+click wired up like DataTable.lua's
-- item cells (BuildRow, ItemLinkId column) when `itemLink` is given -
-- Classic Era's FontString has no SetHyperlinksEnabled (that's what the
-- single-FontString-with-embedded-links approach relied on, and it doesn't
-- exist here), so each item link needs its own mouse-enabled widget instead
-- of one shared region doing per-link hit-testing.
-- The single-line height of GameFontHighlight text, measured once and
-- reused for every recommendation row/segment - matches introLbl/skillLbl/
-- recommendationsLbl's own natural (unforced) Label height exactly, instead
-- of guessing at a constant that ends up taller than the actual glyphs and
-- reads as extra vertical space between rows.
local ROW_TEXT_HEIGHT
local function GetRowTextHeight()
    if not ROW_TEXT_HEIGHT then
        local probe = AceGUI:Create("Label")
        probe:SetFontObject(GameFontHighlight)
        probe:SetText("Wg")
        ROW_TEXT_HEIGHT = math.ceil(probe.label:GetStringHeight())
        AceGUI:Release(probe)
    end
    return ROW_TEXT_HEIGHT
end

local function AddRecommendationSegment(group, text, itemLink)
    local lbl = AceGUI:Create("Label")
    lbl:SetFontObject(GameFontHighlight)
    lbl:SetText(text)
    lbl:SetWidth(math.ceil(lbl.label:GetStringWidth()) + 2)
    lbl:SetHeight(GetRowTextHeight())

    if itemLink then
        lbl.frame:EnableMouse(true)
        lbl.frame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(lbl.frame, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)
        lbl.frame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        lbl.frame:SetScript("OnMouseUp", function()
            if IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(itemLink)
            end
        end)
    end

    group:AddChild(lbl)
end

-- A Flow-layout SimpleGroup that AddRecommendationSegment's calls append
-- into left-to-right - i.e. one logical row.
local function BuildRecommendationRow(scroll)
    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("Flow")
    row:SetFullWidth(true)
    row:SetAutoAdjustHeight(false)
    row:SetHeight(GetRowTextHeight())
    scroll:AddChild(row)
    return row
end

-- Clears `row`'s current segments (its placeholder, or a previous fill) and
-- adds fresh ones from `segments`, an ordered list of either plain strings
-- (plain text) or `{ link = itemLink }` tables (clickable/tooltippable item
-- link) - see AddRecommendationSegment.
local function FillRecommendationRow(row, segments)
    row:ReleaseChildren()
    for _, segment in ipairs(segments) do
        if type(segment) == "table" then
            AddRecommendationSegment(row, segment.link, segment.link)
        else
            AddRecommendationSegment(row, segment)
        end
    end
end

-- Two rows mixing plain text with 5 resolved item links: gloves (Alliance,
-- Horde) on the first row, enchant + 2 materials on the second - see
-- `recommendations`' shape on GatheringPage:AddHeader. Items load
-- asynchronously (Item:CreateFromItemID + ContinueOnItemLoad - same API
-- DataTable.lua's BuildRow uses for its ItemLinkId column), so the first
-- row shows a placeholder until all 5 have resolved, then both rows are
-- filled in one pass.
local function BuildRecommendationLinksRow(scroll, recommendations)
    local itemIds = {
        2119,
        711,
        recommendations.enchantItemId,
        recommendations.materialItemIds[1],
        recommendations.materialItemIds[2],
    }

    local glovesheaderRow = BuildRecommendationRow(scroll)
    local glovesAllianceRow = BuildRecommendationRow(scroll)
    local glovesHordeRow = BuildRecommendationRow(scroll)
    local enchantRow = BuildRecommendationRow(scroll)
    --AddRecommendationSegment(glovesRow, "Loading recommendations...")

    local links = {}
    local pending = #itemIds

    local function finalize()
        if pending > 0 then
            return
        end

        FillRecommendationRow(glovesheaderRow, {
            "1.1) Grab white gloves from your Faction's starting area",
        })

        FillRecommendationRow(glovesAllianceRow, {
            "1.1.1) Alliance: ",
            { link = links[1] },
            " - Northshire Abbey, Darnassus, Kharanos",
        })

        FillRecommendationRow(glovesHordeRow, {
            "1.1.2) Horde: ",
            { link = links[2] },
            " - Valley of Trials, Undercity, Deathknell",
        })

        FillRecommendationRow(enchantRow, {
            "1.2) Enchant it with ",
            { link = links[3] },
            " - ",
            { link = links[4] },
            "x3 ",
            { link = links[5] },
            "x3",
        })
    end

    for i, itemId in ipairs(itemIds) do
        local item = Item:CreateFromItemID(itemId)
        if item:IsItemEmpty() then
            links[i] = ("Item #%d"):format(itemId)
            pending = pending - 1
        else
            item:ContinueOnItemLoad(function()
                links[i] = item:GetItemLink()
                pending = pending - 1
                finalize()
            end)
        end
    end
    finalize()
end

-- Adds the skill label + spacer + expansion radio group + spacer + DataTable
-- to `scroll`, then, if `recommendations` is given, a "Recommendations:"
-- section below the table: a shared intro line and a line of gear links
-- (`recommendations.allianceGlovesId`, `.hordeGlovesId`, `.enchantItemId`,
-- `.materialItemIds` - a 2-item array), all plain itemIDs.
-- `recommendations` is optional - gathering professions that don't have a
-- gear recommendation (e.g. Skinning) should just pass nil.
-- `parent` is passed through to DataTable:Build unchanged (see
-- DataTable.lua).
function GatheringPage:AddHeader(scroll, parent, profession, data, recommendations)
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

    scroll:AddChild(BuildSpacer())

    -- Replaced in place (see RebuildTable) whenever the radio group's
    -- selected expansion changes, rather than rebuilding the whole page.
    local tableWidget

    -- The spacer directly below the table - assigned further down, once it
    -- exists, but declared here so RebuildTable's closure can see it.
    -- RebuildTable inserts the table before it via AddChild's beforeWidget
    -- param instead of appending, so a rebuilt table lands back in its
    -- original spot instead of after the trailing spacer/Recommendations
    -- label added below.
    local trailingSpacer

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
        scroll:AddChild(tableWidget, trailingSpacer)
    end

    local radioGroup, initialExpansion = BuildExpansionRadioGroup(RebuildTable)
    scroll:AddChild(radioGroup)

    scroll:AddChild(BuildSpacer())

    -- trailingSpacer stays nil (RebuildTable just appends the table) when
    -- there's no recommendations section to keep it above.
    if recommendations then
        trailingSpacer = BuildSpacer()
        scroll:AddChild(trailingSpacer)

        local recommendationsLbl = AceGUI:Create("Label")
        recommendationsLbl:SetFullWidth(true)
        recommendationsLbl:SetFontObject(GameFontHighlightLarge)
        recommendationsLbl:SetText("Recommendations:")
        scroll:AddChild(recommendationsLbl)

        local introLbl = AceGUI:Create("Label")
        introLbl:SetFullWidth(true)
        introLbl:SetFontObject(GameFontHighlight)
        introLbl:SetText("1) Gloves with +profession skill")
        scroll:AddChild(introLbl)

        BuildRecommendationLinksRow(scroll, recommendations)

        scroll:AddChild(BuildSpacer())
    end

    RebuildTable(initialExpansion)
end
