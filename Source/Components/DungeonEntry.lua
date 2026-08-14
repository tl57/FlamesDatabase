--[[-----------------------------------------------------------------------------
DungeonEntry
Represents one dungeon's data: name, zone, mob/boss level ranges, and its
quests.
-----------------------------------------------------------------------------]]

local AceGUI = LibStub("AceGUI-3.0")

DungeonEntry = {}
DungeonEntry.__index = DungeonEntry

-- options = {
--     name       = <dungeon name>,
--     zoneid     = <zone id>,
--     bossLevels = { <level>, ... },
--     minMobLvl  = <number>,
--     maxMobLvl  = <number>,
--     quests     = { <Quest>, ... },
-- }
function DungeonEntry:New(options)
    return setmetatable({
        name       = options.name,
        zoneid     = options.zoneid,
        bossLevels = options.bossLevels or {},
        minMobLvl  = options.minMobLvl,
        maxMobLvl  = options.maxMobLvl,
        quests     = options.quests or {},
    }, DungeonEntry)
end

-- Resolves `quest.questId` into a real quest hyperlink where possible
-- (falls back to a manually-built "quest:id:level" link, in the same
-- hyperlink format, if the client doesn't have the quest's title cached
-- yet), and wires GameTooltip:SetHyperlink on hover and ChatEdit_InsertLink
-- on shift-click - same behavior as item links elsewhere in this addon (see
-- DataTable.lua's WireItemCell / GatheringPage.lua's AddRecommendationSegment).
-- Classic Era's FontString has no SetHyperlinksEnabled, so the link needs
-- its own mouse-enabled widget rather than relying on embedded link markup
-- in plain text being clickable on its own.
local function BuildQuestLinkRow(quest)
    local questLink = (GetQuestLink and GetQuestLink(quest.questId))
        or ("|cffffff00|Hquest:%d:%d|h[%s]|h|r"):format(quest.questId, quest.minLvl or 0, quest.name or ("Quest " .. quest.questId))

    local row = AceGUI:Create("Label")
    row:SetFullWidth(true)
    row:SetFontObject(GameFontHighlight)
    row:SetText(questLink)

    -- ANCHOR_RIGHT would anchor off this Label's own frame, which spans the
    -- full row width (SetFullWidth above) - far to the right of wherever the
    -- mouse actually is over the (left-aligned, much narrower) text.
    -- ANCHOR_CURSOR keeps the tooltip next to the mouse regardless of where
    -- in the row it's hovering, matching how item links visually behave.
    row.frame:EnableMouse(true)
    row.frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(row.frame, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(questLink)
        GameTooltip:Show()
    end)
    row.frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    row.frame:SetScript("OnMouseUp", function()
        if IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(questLink)
        end
    end)

    -- AceGUI's Label widget pool is shared across the whole addon (and
    -- every other AceGUI-3.0 consumer) and never resets custom frame
    -- scripts/EnableMouse on acquire, so without this cleanup this exact
    -- frame could later be recycled as an unrelated Label elsewhere (e.g.
    -- a different tab) while still carrying this quest's tooltip/click
    -- handlers - the tooltip/link would "bleed through" onto that widget.
    row:SetCallback("OnRelease", function(self)
        self.frame:EnableMouse(false)
        self.frame:SetScript("OnEnter", nil)
        self.frame:SetScript("OnLeave", nil)
        self.frame:SetScript("OnMouseUp", nil)
    end)

    return row
end

-- Add the dungeon name, then one row per quest in this dungeon, to `scroll`,
-- followed by a spacer.
function DungeonEntry:AddRows(scroll)
    local nameLbl = AceGUI:Create("Label")
    nameLbl:SetFullWidth(true)
    nameLbl:SetFontObject(GameFontHighlightLarge)
    nameLbl:SetText(self.name)
    scroll:AddChild(nameLbl)

    for _, quest in ipairs(self.quests) do
        scroll:AddChild(BuildQuestLinkRow(quest))
    end

    scroll:AddChild(GeneralUI:BuildSpacer())
end

--[[-----------------------------------------------------------------------------
Quest
Represents a single quest tied to a dungeon.
-----------------------------------------------------------------------------]]

Quest = {}
Quest.__index = Quest

-- options = {
--     name        = <quest name>,
--     questId     = <quest id>,
--     minLvl      = <number>,
--     shareable   = <boolean>,
--     chain       = <boolean>,
--     faction     = <faction>,
--     npcName     = <string>,
--     npcLocation = <string>,
--     effort      = <string/number>,
--     note        = <string>,
-- }
function Quest:New(options)
    return setmetatable({
        name        = options.name,
        questId     = options.questId,
        minLvl      = options.minLvl,
        shareable   = options.shareable,
        chain       = options.chain,
        faction     = options.faction,
        npcName     = options.npcName,
        npcLocation = options.npcLocation,
        effort      = options.effort,
        note        = options.note,
    }, Quest)
end
