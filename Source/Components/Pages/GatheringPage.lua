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

    -- Unsubscribes this page from the global expansion dropdown (mainframe.lua)
    -- when its scroll frame is torn down - CategoryTabs:Render releases the
    -- whole tab tree on every tab switch, so without this a stale listener
    -- would keep firing RebuildTable against a released scroll/tableWidget.
    local subscriptionKey = {}
    scroll:SetCallback("OnRelease", function()
        Functions_ExpansionState:Unsubscribe(subscriptionKey)
    end)

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

    Functions_ExpansionState:Subscribe(subscriptionKey, function(level)
        RebuildTable(level)
    end)

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

    RebuildTable(Functions_ExpansionState:GetLevel())
end
