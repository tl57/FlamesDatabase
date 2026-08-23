--[[-----------------------------------------------------------------------------
ProspectingPage
Header + table builder for the "Prospecting" page: the expansion dropdown
(mirrors GatheringPage.lua's, capped to ProspectingData's rows instead of a
DataTable's columns since Prospecting's columns aren't per-expansion), and a
DataTable built from ProspectingData - reusing DataTable rather than
GatheringPage, since this table's shape (multiple gem-group columns instead
of a skill-breakpoint grid) has nothing in common with GatheringPage's.
-------------------------------------------------------------------------------]]
ProspectingPage = {}

-- Resolved gem data, keyed by itemId ({ link = coloredItemLink, icon =
-- iconFileID }), populated once and reused for the rest of the session
-- (Prospecting's gem items don't change at runtime). `nil` until
-- EnsureResolved has heard back for that itemId.
local resolvedItems = {}
-- itemId -> true while its async load is in flight, so a gem referenced by
-- several ore rows (e.g. Blood Garnet) only ever gets one ContinueOnItemLoad
-- registered instead of one per row that references it.
local pendingIds = {}

-- Kicks off (once per itemId) an async load resolving `itemId` to its real
-- link + icon. `fallbackName` is cached as the permanent result (with no
-- icon) if the item has no data on this client at all (IsItemEmpty, e.g. an
-- item that doesn't exist on Classic Era) - this doesn't retry, since that
-- outcome can't change mid-session. `onResolved` fires once, the first time
-- this itemId's real link becomes available, so the caller knows to redraw
-- with it.
local function EnsureResolved(itemId, fallbackName, onResolved)
    if resolvedItems[itemId] or pendingIds[itemId] then
        return
    end

    local item = Item:CreateFromItemID(itemId)
    if item:IsItemEmpty() then
        resolvedItems[itemId] = { link = fallbackName }
        return
    end

    pendingIds[itemId] = true
    -- pcall-wrapped the same way GeneralUI:WireItemCell wraps its own
    -- ContinueOnItemLoad call - on this client, some item IDs make
    -- ContinueOnItemLoad throw internally (Blizzard_ObjectAPI/Classic/
    -- Item.lua, "table index is nil") instead of just never resolving.
    -- Without this, that error would propagate all the way up through
    -- BuildRows/RebuildTable and abort the whole table build over a single
    -- gem. pendingIds[itemId] is deliberately left true when this happens -
    -- same as Mining/Herbalism's item icons in this situation, that gem just
    -- keeps showing its plain name for the rest of the session.
    pcall(item.ContinueOnItemLoad, item, function()
        pendingIds[itemId] = nil
        resolvedItems[itemId] = { link = item:GetItemLink() or fallbackName, icon = item:GetItemIcon() }
        onResolved()
    end)
end

-- One entry per gem - `{ icon, text, itemLink }`, matching DataTable's
-- list-cell format (see AcquireSubRow/ComputeRowHeight in DataTable.lua,
-- which auto-grows that cell's row to fit however many entries this
-- returns): the gem's resolved icon/link if EnsureResolved already has it
-- (itemLink also wires that entry's tooltip/shift-click), else just its
-- plain name with no icon/link as a placeholder until it does. `group` is
-- one entry of a row's `commonGems`/`extraGems` ({ chance, gems }), or nil
-- for a tier-row that doesn't have a group at that index (e.g. an ore's
-- later commonGems tiers never have an extraGems entry to match).
local function GemGroupEntries(group, onResolved)
    if not group or not group.gems or #group.gems == 0 then
        return nil
    end

    local entries = {}
    for i, gem in ipairs(group.gems) do
        EnsureResolved(gem.itemLink, gem.name, onResolved)
        local resolved = resolvedItems[gem.itemLink]
        entries[i] = {
            icon = resolved and resolved.icon,
            text = (resolved and resolved.link) or gem.name,
            itemLink = resolved and resolved.icon and resolved.link,
        }
    end
    return entries
end

-- ProspectingData.columns as DataTable expects: `colName` -> `title` (its
-- own field name for a header label; ProspectingData's rows/columns predate
-- and aren't otherwise shaped to match DataTable's own field names), and a
-- numeric `autoWidth` (this data file's shorthand for a fixed width on a
-- non-Name column, since DataTable's `autoWidth` only auto-measures
-- column 1) resolved into a plain `width`. `mergeRepeats` (Name/Skill - see
-- ProspectingData.lua) passes straight through to DataTable, which vertically
-- merges a column's consecutive equal-value rows into one cell. Rebuilt fresh
-- each call rather than reusing/mutating ProspectingData.columns in place, so
-- this data file stays plain declarative data.
local function BuildColumns()
    local columns = {}
    for i, col in ipairs(ProspectingData.columns) do
        local width = col.width
        if not width and i > 1 and type(col.autoWidth) == "number" then
            width = col.autoWidth
        end
        columns[i] = {
            id = col.id,
            title = col.colName,
            width = width,
            autoWidth = (i == 1) and col.autoWidth or nil,
            mergeRepeats = col.mergeRepeats,
        }
    end
    return columns
end

-- DataTable rows built from ProspectingData.rows - one DataTable row per gem
-- tier (i.e. per commonGems entry) rather than per ore, so an ore with
-- several tiers (e.g. Titanium's 65/25/4%) becomes several rows instead of
-- spreading them across several column-pairs. Name/ItemLinkId/Introduced/
-- Skill repeat identically on every one of an ore's tier-rows - DataTable's
-- mergeRepeats (see BuildColumns) collapses those repeats into one merged
-- cell rather than this needing to null them out on the later rows.
-- %_Uncommon/Uncommon are positional exactly like %_Common/Common_1 (index i
-- into extraGems, not merged/spanned) - in practice that's always just the
-- ore's first tier-row, since every row's extraGems has exactly one entry.
local function BuildRows(onGemResolved)
    local rows = {}
    for _, row in ipairs(ProspectingData.rows) do
        local commonGems = row.commonGems or {}
        local extraGems = row.extraGems or {}
        local tierCount = math.max(#commonGems, #extraGems, 1)

        for i = 1, tierCount do
            local common = commonGems[i]
            local uncommon = extraGems[i]

            rows[#rows + 1] = {
                colName = row.oreName,
                ItemLinkId = row.oreLink,
                Introduced = row.expansion,
                skill = row.skillReq,
                ["%_Common_1"] = common and common.chance,
                Common_1 = GemGroupEntries(common, onGemResolved),
                ["%_Uncommon"] = uncommon and uncommon.chance,
                Uncommon = GemGroupEntries(uncommon, onGemResolved),
            }
        end
    end
    return rows
end

-- Adds the expansion dropdown + DataTable to `scroll`. The table is rebuilt
-- in place (mirrors GatheringPage.lua's RebuildTable) both when the dropdown
-- changes and, debounced, whenever a gem's real item link finishes loading
-- after the initial build - pageReleased guards a load that resolves after
-- this page's own scroll frame has already been torn down (tab switched
-- away), matching DungeonEntry.lua's identical QUEST_LOG_UPDATE debounce.
function ProspectingPage:AddHeader(scroll)
    local tableWidget
    local currentExpansion
    local pageReleased = false
    local refreshScheduled = false
    local RebuildTable
    local subscriptionKey = {}

    local function ScheduleRefresh()
        if pageReleased or refreshScheduled then
            return
        end
        refreshScheduled = true
        C_Timer.After(0.2, function()
            refreshScheduled = false
            if not pageReleased then
                RebuildTable(currentExpansion)
            end
        end)
    end

    RebuildTable = function(selectedExpansion)
        if tableWidget then
            for idx, child in ipairs(scroll.children) do
                if child == tableWidget then
                    table.remove(scroll.children, idx)
                    break
                end
            end
            Functions_Ace:ReleaseWidget(tableWidget)
        end
        tableWidget = DataTable:Build(nil, {
            columns = BuildColumns(),
            rows = BuildRows(ScheduleRefresh),
        }, selectedExpansion)
        scroll:AddChild(tableWidget)
    end

    scroll:SetCallback("OnRelease", function()
        pageReleased = true
        Functions_ExpansionState:Unsubscribe(subscriptionKey)
    end)

    currentExpansion = Functions_ExpansionState:GetLevel()
    Functions_ExpansionState:Subscribe(subscriptionKey, function(level)
        currentExpansion = level
        RebuildTable(level)
    end)

    RebuildTable(currentExpansion)
end
