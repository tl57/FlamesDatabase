local AceGUI = LibStub("AceGUI-3.0")

DungeonInfo = {}

local Dungeons = {
    RagefireChasmInfo,
    DeadminesInfo,
}

local ROW_HEIGHT = 14

-- Returns the next reusable FontString from `content`'s row pool (creating
-- one if needed), reset to a blank state. `content.rowsUsed` must be reset
-- to 0 at the start of a build. Mirrors DataTable.lua's AcquireRow/
-- AcquireCell - `content` (a SimpleGroup's own .content frame) is recycled
-- across AceGUI:Release/:Create cycles (e.g. every time this section is
-- collapsed/expanded or its tab is revisited), so creating a fresh
-- FontString on every build here (as an earlier version of this file did)
-- left old rows permanently attached and unhidden, accumulating one full
-- extra set on every rebuild.
local function AcquireInfoRow(content)
    content.rowPool = content.rowPool or {}
    content.rowsUsed = content.rowsUsed + 1
    local n = content.rowsUsed

    local fontString = content.rowPool[n]
    if not fontString then
        fontString = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fontString:SetJustifyH("LEFT")
        content.rowPool[n] = fontString
    end

    fontString:Show()
    return fontString
end

-- Add a row showing `text` to `content` (a SimpleGroup's .content frame) at
-- `yOffset`. Returns the yOffset for the next row.
local function AddInfoRow(content, text, yOffset)
    local fontString = AcquireInfoRow(content)
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    fontString:SetText(text)
    return yOffset + ROW_HEIGHT
end

local INFO_CONTENT_WIDTH = 700

-- Build and return the content widget (zone id, mob levels, one row per
-- boss) for `dungeon`.
local function BuildInfoContent(dungeon)
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("List")
    group:SetWidth(INFO_CONTENT_WIDTH)
    -- Rows are pooled raw FontStrings, not real AceGUI children of `group`
    -- (see AddInfoRow) - so group.children is always empty, and without
    -- this, AceGUI's own auto-height logic would recompute group's height
    -- from that empty list and reset it to 0 (see DataTable.lua's
    -- identical use of SetAutoAdjustHeight(false), for the same reason).
    group:SetAutoAdjustHeight(false)

    local content = group.content
    -- Defensive: this exact frame may have previously been recycled by
    -- some other widget (e.g. DataTable.lua's own defensive "hide every
    -- leftover child" cleanup used to sweep up .content along with its
    -- pooled rows/cells, permanently hiding it since nothing else ever
    -- showed it back - fixed at the source, but re-asserting this costs
    -- nothing and guards against any other code with the same mistake).
    content:Show()
    content.rowsUsed = 0

    local y = 0
    y = AddInfoRow(content, ("Zone ID: %s"):format(dungeon.zoneid or "?"), y)
    y = AddInfoRow(content, ("Mob Levels: %s-%s"):format(dungeon.minMobLevel or "?", dungeon.maxMobLevel or "?"), y)

    y = AddInfoRow(content, "Boss Levels:", y)
    for _, boss in ipairs(dungeon.bosses or {}) do
        y = AddInfoRow(content, ("%s: %s"):format(boss.name, boss.level), y)
    end

    -- Hide any pooled rows left over from a build with more rows than this
    -- one (e.g. switching between dungeons with different boss counts).
    for n = content.rowsUsed + 1, #content.rowPool do
        content.rowPool[n]:Hide()
    end

    group:SetHeight(y)

    -- Same defensive cleanup as DataTable.lua's group.OnRelease: if this
    -- exact frame later gets recycled for something entirely unrelated
    -- (AceGUI's SimpleGroup pool is shared client-wide), make sure our own
    -- rows are hidden first so they can't bleed through underneath it.
    group.OnRelease = function(self)
        for _, fontString in ipairs(self.content.rowPool or {}) do
            fontString:Hide()
        end
    end

    return group
end

-- Build and return the content widget for the "Dungeon Info" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function DungeonInfo:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    for _, dungeon in ipairs(Dungeons) do
        GeneralUI:AddCollapsibleSection(scroll, dungeon.name, function()
            return BuildInfoContent(dungeon)
        end)
    end

    return scroll
end
