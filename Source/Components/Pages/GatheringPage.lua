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
local profession = nil

GatheringPage = {}

-- A label followed by a dropdown, on the same row, offering one option per
-- expansion `data` actually has columns for, with the one matching the
-- realm's current expansion pre-selected. Uses AceGUI's own Dropdown widget
-- instead of hand-built radio buttons, so there's no per-option width
-- budgeting or exclusivity handling to get wrong - the row always has
-- exactly two fixed-width children (the label, the dropdown) no matter how
-- many expansions end up in the dropdown's list. `onSelect(level)` fires
-- whenever the user picks a different option (not for the initial
-- pre-selection - the caller already gets that back as the second return
-- value).
-- Returns the group widget and the initially selected level.
local function BuildExpansionDropdown(onSelect, data)
    local currentLevel = Functions_General:GetServerExpansionLevel()

    -- Cap the offered expansions at what `data.columns` actually has data
    -- for (i.e. the highest `col.exp` present), not at what the client
    -- currently running this addon happens to support - those are different
    -- things: Functions_General:GetHighestSupportedExpansion reflects the
    -- .toc's declared game-version compatibility (e.g. it reports Classic
    -- while running on the Classic Era client even if the .toc also lists
    -- TBC, since that's the closest match to *this* client), whereas here
    -- we want every expansion this table has real data for, regardless of
    -- which client is currently viewing it. Falls back to Classic if no
    -- column declares an `exp` at all.
    local highestSupported = LE_EXPANSION_CLASSIC
    for _, col in ipairs(data.columns or {}) do
        if col.exp and col.exp > highestSupported then
            highestSupported = col.exp
        end
    end

    local levels = {}
    local names = {}
    for _, level in ipairs(Functions_General:GetExpansionLevels()) do
        if level <= highestSupported then
            levels[#levels + 1] = level
            names[level] = Functions_General:GetExpansionName(level)
        end
    end

    local selected = levels[1]
    for _, level in ipairs(levels) do
        if level == currentLevel then
            selected = level
            break
        end
    end

    -- No dropdown:SetLabel(...) here - that renders the label above the
    -- dropdown instead of beside it. Leaving it unset keeps the dropdown at
    -- its default 26px-tall, no-label layout so it can sit inline with its
    -- own separate Label widget below instead.
    local DROPDOWN_WIDTH = 160
    local dropdown = Functions_Ace:CreateDropdown()
    dropdown:SetWidth(DROPDOWN_WIDTH)
    -- AceGUI's Dropdown widget has no exported method for this - its
    -- UIDropDownMenuTemplate-based text is center-justified by default, so
    -- the selected-value text is reached directly via the widget's own
    -- `.text` FontString field.
    dropdown.text:SetJustifyH("LEFT")
    -- `levels` is already ascending (GetExpansionLevels()'s own order) -
    -- passed as the explicit order so SetList doesn't fall back to sorting
    -- the LE_EXPANSION_* values itself.
    dropdown:SetList(names, levels)
    dropdown:SetValue(selected)
    dropdown:SetCallback("OnValueChanged", function(_, _, level)
        onSelect(level)
    end)

    local label = Functions_Ace:CreateLabel()
    label:SetFontObject(GameFontHighlightLarge)
    label:SetText("Current Expansion Data:")
    local labelWidth = math.ceil(label.label:GetStringWidth()) + 8
    label:SetWidth(labelWidth)

    local totalWidth = labelWidth + DROPDOWN_WIDTH
    local group = Functions_Ace:CreateGroup()
    group:SetLayout("Flow")
    group:SetWidth(totalWidth)
    -- SimpleGroup's Flow layout reads content.width directly, which SetWidth
    -- only updates asynchronously via the frame's OnSizeChanged - without
    -- this a group recycled from AceGUI's shared SimpleGroup pool can carry
    -- over a stale, narrower width and wrap the dropdown onto its own row
    -- (see DungeonInfo.lua/DungeonEntry.lua's identical line).
    group.content.width = totalWidth
    group:AddChild(label)
    group:AddChild(dropdown)

    return group, selected
end

-- A Label showing `text`, with tooltip+click wired up like DataTable.lua's
-- item cells (WireItemCell) when `itemLink` is given -
-- Classic Era's FontString has no SetHyperlinksEnabled (that's what the
-- single-FontString-with-embedded-links approach relied on, and it doesn't
-- exist here), so each item link needs its own mouse-enabled widget instead
-- of one shared region doing per-link hit-testing.
local function AddRecommendationSegment(group, text, itemLink, iconId)
    if iconId then
        local icon = Functions_Ace:CreateLabel()
        icon:SetText("")
        icon:SetImage(iconId)
        local size = GeneralUI:GetRowTextHeight()
        icon:SetImageSize(size, size)
        icon:SetWidth(size)
        icon:SetHeight(size)
        group:AddChild(icon)
    end

    local lbl = Functions_Ace:CreateLabel()
    lbl:SetFontObject(GameFontHighlight)
    lbl:SetText(text)
    lbl:SetWidth(math.ceil(lbl.label:GetStringWidth()) + 2)
    lbl:SetHeight(GeneralUI:GetRowTextHeight())

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

        -- AceGUI's Label widget pool is shared across the whole addon and
        -- never resets custom frame scripts/EnableMouse on acquire, so
        -- without this cleanup this exact frame could later be recycled as
        -- an unrelated Label elsewhere while still carrying this item's
        -- tooltip/click handlers - the tooltip/link would "bleed through"
        -- onto that widget (see DungeonEntry.lua's BuildQuestLinkRow for
        -- the same fix applied to quest links).
        lbl:SetCallback("OnRelease", function(self)
            self.frame:EnableMouse(false)
            self.frame:SetScript("OnEnter", nil)
            self.frame:SetScript("OnLeave", nil)
            self.frame:SetScript("OnMouseUp", nil)
        end)
    end

    group:AddChild(lbl)
end

-- A Flow-layout SimpleGroup that AddRecommendationSegment's calls append
-- into left-to-right - i.e. one logical row.
local function BuildRecommendationRow(scroll)
    local row = Functions_Ace:CreateGroup()
    row:SetLayout("Flow")
    row:SetFullWidth(true)
    row:SetAutoAdjustHeight(false)
    row:SetHeight(GeneralUI:GetRowTextHeight())
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
            AddRecommendationSegment(row, segment.link, segment.link, segment.icon)
        else
            AddRecommendationSegment(row, segment)
        end
    end
end

-- Two rows mixing plain text with 5 resolved item links: gloves (Alliance,
-- Horde) on the first row, enchant + 2 materials on the second - see
-- `recommendations`' shape on GatheringPage:AddHeader. Items load
-- asynchronously (Item:CreateFromItemID + ContinueOnItemLoad - same API
-- DataTable.lua's WireItemCell uses), so the first
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
    local iconIds = {
        132952,
        132961,
        recommendations.enchantItemIconId,
        recommendations.materialItemIconIds[1],
        recommendations.materialItemIconIds[2],
    }

    local glovesheaderRow = BuildRecommendationRow(scroll)
    local glovesAllianceRow = BuildRecommendationRow(scroll)
    local glovesHordeRow = BuildRecommendationRow(scroll)
    local enchantRow = BuildRecommendationRow(scroll)

    local links = {}
    local pendingItemIds = #itemIds

    local function finalize()
        if pendingItemIds > 0 then
            return
        end

        FillRecommendationRow(glovesheaderRow, {
            "1.1) Grab a pair of white gloves from your Faction's starting area",
        })

        FillRecommendationRow(glovesAllianceRow, {
            "1.1.1) Alliance: ",
            { link = links[1], icon = iconIds[1] },
            " - Northshire Abbey, Darnassus, Kharanos",
        })

        FillRecommendationRow(glovesHordeRow, {
            "1.1.2) Horde: ",
            { link = links[2], icon = iconIds[2] },
            " - Valley of Trials, Undercity, Deathknell",
        })

        FillRecommendationRow(enchantRow, {
            "1.2) Enchant it with ",
            { link = links[3], icon = iconIds[3] },
            " - ",
            { link = links[4], icon = iconIds[4] },
            "x3 ",
            { link = links[5], icon = iconIds[5] },
            "x3",
        })
    end

    for i, itemId in ipairs(itemIds) do
        local item = Item:CreateFromItemID(itemId)
        if item:IsItemEmpty() then
            links[i] = ("Item #%d"):format(itemId)
            pendingItemIds = pendingItemIds - 1
        else
            item:ContinueOnItemLoad(function()
                links[i] = item:GetItemLink()
                pendingItemIds = pendingItemIds - 1
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
    profession = profession
    local skillLbl = Functions_Ace:CreateLabel()
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

    scroll:AddChild(GeneralUI:BuildSpacer())

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
            Functions_Ace:ReleaseWidget(tableWidget)
        end
        tableWidget = DataTable:Build(parent, data, selectedExpansion)
        scroll:AddChild(tableWidget, trailingSpacer)
    end

    local expansionDropdown, initialExpansion = BuildExpansionDropdown(RebuildTable, data)
    scroll:AddChild(expansionDropdown)

    scroll:AddChild(GeneralUI:BuildSpacer())

    -- trailingSpacer stays nil (RebuildTable just appends the table) when
    -- there's no recommendations section to keep it above.
    if recommendations then
        trailingSpacer = GeneralUI:BuildSpacer()
        scroll:AddChild(trailingSpacer)

        local recommendationsLbl = Functions_Ace:CreateLabel()
        recommendationsLbl:SetFullWidth(true)
        recommendationsLbl:SetFontObject(GameFontHighlightLarge)
        recommendationsLbl:SetText("Recommendations:")
        scroll:AddChild(recommendationsLbl)

        local introLbl = Functions_Ace:CreateLabel()
        introLbl:SetFullWidth(true)
        introLbl:SetFontObject(GameFontHighlight)
        introLbl:SetText("1) Gloves with +".. profession .." skill")
        scroll:AddChild(introLbl)

        BuildRecommendationLinksRow(scroll, recommendations)

        scroll:AddChild(GeneralUI:BuildSpacer())
    end

    RebuildTable(initialExpansion)
end
