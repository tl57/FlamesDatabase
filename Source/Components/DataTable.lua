--[[-----------------------------------------------------------------------------
DataTable
A reusable columnar table component. Sized to fit all of its rows; relies on
the surrounding page to provide scrolling if the table doesn't fit.

Takes a declarative structure:
    DataTable:Build(parent, {
        width   = 700,          -- optional, default is the sum of column widths
        columns = {
            { id = "Name", width = 200 },
            { id = "OrangeClassicMine", width = 60, group = "Mine", exp = LE_EXPANSION_CLASSIC },
            ...
        },
        rows = {
            { Name = "Copper Vein", OrangeClassicMine = 1, ... },
            ...
        },
    }, selectedExpansion)

Rows are keyed by column id. Values that are nil render as empty cells.
Consecutive columns sharing the same `group` value are merged into one header
cell; other columns show column.title if provided, else column.name.

`columns[1].autoWidth = true` (instead of giving it a fixed `width`) sizes
the Name column to fit the widest of the rows it's about to show (its name
text, icon if any, expansion suffix if any - see MeasureTextWidth) rather
than a manually guessed number - recomputed every DataTable:Build call, so it
resizes if `selectedExpansion` changes which rows are shown. Only meaningful
on column[1]; every other column still needs an explicit `width`.

`options.rowHeight` overrides the default row height (ROW_HEIGHT below) for
every row in this table - useful when a column's word-wrapped text needs a
taller row so its second line doesn't overlap the row border below.

Non-Name columns can tint their text: `column.background` (a key into
CELL_BACKGROUND_COLORS) gives every cell in the column the same fixed color;
`column.valueColors` (e.g. { Horde = {0.9,0.2,0.2}, Alliance = {0.3,0.55,0.95} })
instead looks the color up by each cell's own value - values with no entry
stay untinted. At most one of the two applies per column in practice.

`column.valueBackgrounds` is the same value-lookup idea as `valueColors`, but
fills the cell's own background texture instead of its text (e.g.
{ Low = {0,1,0}, Medium = {1,1,0}, High = {1,0,0} }, each {r,g,b[,a]} -
alpha defaults to 0.35). A value with no entry stays unfilled.

`column.info` (an array of strings, one per tooltip line - typically a legend
of the column's possible values, each optionally colorized via
Functions_General:ColorizeText) puts a small "(i)" icon at the header cell's
right edge; hovering it shows the column's title followed by those lines as a
GameTooltip, nothing otherwise (see AcquireInfoIcon).

If a row has an `ItemLinkId` (an itemID, not part of `columns`), the Name
column shows that item's icon and gets tooltip/shift-click-to-chat behavior,
while still displaying the row's own Name text (see WireItemCell).

If a row has a `QuestLinkId` (a questID, not part of `columns`) instead, the
Name column gets the same tooltip/shift-click-to-chat behavior wired to a
quest hyperlink rather than an item one (see WireQuestCell). An optional
`QuestLevel` (also not part of `columns`) is used when building the link's
level field. ItemLinkId and QuestLinkId are mutually exclusive per row.

A column with `id = "Status"` is a special case: it never reads a `Status`
field from the row (none is ever set) - instead it derives quest-completion
status from the row's own `QuestLinkId` via Functions_Quests, showing a green
checkmark icon, "Accepted" text, or a red X icon (see BuildRow).

When `selectedExpansion` is given (one of Functions_General:GetExpansionLevels()),
only columns with no `exp` or with `exp == selectedExpansion` are included -
`exp` otherwise has no visual effect of its own (no separate header row for
it), it's purely a filtering key. Rows are filtered the same way by their own
`Introduced` field (also not part of `columns`): a row is included only if it
has no `Introduced`, or `Introduced <= selectedExpansion` - e.g. a herb with
`Introduced = LE_EXPANSION_BURNING_CRUSADE` is left out entirely while Classic
is selected, since LE_EXPANSION_* values increase with each expansion and this
is a plain `<=` comparison, this keeps working unmodified as later expansions
are added - nothing here needs to change.

A row's own `Introduced` also controls its Name column directly: rows
introduced in Classic get no suffix; anything later gets its expansion name
appended in brackets (e.g. "Felweed [TBC]", via Functions_General:GetExpansionName)
in a smaller, deep-pink font right after the name - rendered as a separate
FontString (cell.suffix) since a single FontString can't mix font sizes.
Nothing to update here as later expansions are added, since that function
already has their names.

Row/header frames are pooled per container frame and reused across rebuilds
(see AcquireRow/AcquireCell) rather than always creating new ones - a given
page (e.g. a profession tab) rebuilds its table via a fresh DataTable:Build
call every time it's reselected, and WoW has no API to destroy a frame, so
never reusing them means each rebuild's cost keeps growing with how many
times that recycled container has ever been built.

The container itself is a dedicated custom AceGUI widget type
("FlamesDataTable", see AceGUIWidget-FlamesDataTable.lua) rather than the
stock "SimpleGroup" - AceGUI pools widgets separately per registered type
name, so this guarantees this frame (and the pooled row/cell frames
attached directly to it, bypassing AceGUI's own child-tracking) is only
ever reused for another DataTable, never handed to or received from any
other widget in this addon.

Returns the widget, ready to be added to a page builder.
-------------------------------------------------------------------------------]]
local AceGUI           = LibStub("AceGUI-3.0")

DataTable              = {}

local ROW_HEIGHT       = 20
local HEADER_HEIGHT    = 24
local PADDING          = 8
local ICON_SIZE        = 16
local ICON_TEXT_GAP    = 4

-- Header column info-tooltip icon (see col.info, AcquireInfoIcon, and
-- DataTable:Build's header loop) - Blizzard's own small "(i)" icon, also
-- used by e.g. the Friends List for inline info tooltips.
local INFO_ICON_SIZE    = 14
local INFO_ICON_TEXTURE = "Interface\\FriendsFrame\\InformationIcon"

-- Thin white border settings.
local BORDER_THICKNESS = 1
local BORDER_COLOR     = { 1, 1, 1, 0.5 }
local TEXT_COLOR_DEFAULT = { 1, 1, 1 }

-- Name column's "[TBC]"-style expansion suffix (see BuildRow) - deep pink,
-- deliberately loud so it stands out from the plain-white name text next to it.
local EXPANSION_SUFFIX_COLOR = { 1, 0.078, 0.576 }
-- Shaved off the cell's own font size (see AcquireCell) rather than a fixed
-- size, so the suffix stays proportionally smaller if the base font ever changes.
local EXPANSION_SUFFIX_FONT_SIZE_DELTA = -3

-- Column-identity text colors keyed by a column's `background` name, e.g.
-- { id = "OrangeClassicMine", background = "orange" } -> that column's
-- numbers render in this color, regardless of skill.
local CELL_BACKGROUND_COLORS = {
    orange = { 0.75, 0.55, 0.35 },
    yellow = { 0.75, 0.70, 0.40 },
    green  = { 0.45, 0.60, 0.45 },
    grey   = { 0.55, 0.55, 0.55 },
}

-- Text colors for a numeric cell, based on (playerSkill - cellValue).
local SKILL_DIFF_RED    = { 0.90, 0.15, 0.15 }
local SKILL_DIFF_ORANGE = { 0.90, 0.55, 0.15 }
local SKILL_DIFF_YELLOW = { 0.85, 0.85, 0.15 }
local SKILL_DIFF_GREEN  = { 0.35, 0.75, 0.35 }
local SKILL_DIFF_GREY   = { 0.60, 0.60, 0.60 }

-- diff < 0: red. 0-25: orange. 26-50: yellow. 51-75: green. 100+: grey.
local function SkillDiffColor(diff)
    if diff < 0 then
        return SKILL_DIFF_RED
    elseif diff <= 25 then
        return SKILL_DIFF_ORANGE
    elseif diff <= 50 then
        return SKILL_DIFF_YELLOW
    elseif diff <= 100 then
        return SKILL_DIFF_GREEN
    else
        return SKILL_DIFF_GREY
    end
end

-- Returns the next reusable plain wrapper frame from `container`'s row pool
-- (creating one if the pool doesn't have enough yet), parented under `parent`
-- and reset to a blank state. Used for the header row and each data row.
-- `container.rowsUsed` must be reset to 0 at the start of a build.
local function AcquireRow(container, parent)
    container.rowPool = container.rowPool or {}
    container.rowsUsed = container.rowsUsed + 1
    local n = container.rowsUsed

    local frame = container.rowPool[n]
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        container.rowPool[n] = frame
    end

    frame:SetParent(parent)
    frame:ClearAllPoints()
    frame:Show()
    frame.bg:Hide()
    return frame
end

-- Returns the next reusable bordered/labeled cell from `container`'s cell
-- pool (creating one if needed), parented under `parent` and reset to a blank
-- state (caller sets position, size/border via LayoutCell, background, and
-- text). `container.cellsUsed` must be reset to 0 at the start of a build.
local function AcquireCell(container, parent)
    container.cellPool = container.cellPool or {}
    container.cellsUsed = container.cellsUsed + 1
    local n = container.cellsUsed

    local cell = container.cellPool[n]
    if not cell then
        cell = CreateFrame("Frame", nil, parent)
        cell.bg = cell:CreateTexture(nil, "BACKGROUND")
        cell.bg:SetAllPoints(cell)
        cell.edgeTop = cell:CreateTexture(nil, "BORDER")
        cell.edgeBottom = cell:CreateTexture(nil, "BORDER")
        cell.edgeLeft = cell:CreateTexture(nil, "BORDER")
        cell.edgeRight = cell:CreateTexture(nil, "BORDER")
        for _, tex in ipairs({ cell.edgeTop, cell.edgeBottom, cell.edgeLeft, cell.edgeRight }) do
            tex:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
        end
        cell.icon = cell:CreateTexture(nil, "ARTWORK")
        cell.icon:SetSize(ICON_SIZE, ICON_SIZE)
        cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        -- Cells are a fixed single-line ROW_HEIGHT tall - without this,
        -- long text wraps to a second line that gets clipped by the cell's
        -- fixed height anyway, and (for reasons not fully pinned down)
        -- whether a given cell wraps has been observed to flip inconsistently
        -- depending on how many other DataTables happen to be built/alive at
        -- the same time. Forcing it off keeps every cell single-line always.
        cell.text:SetWordWrap(true)
        cell.text:SetPoint("RIGHT", -PADDING, 0)
        -- Captured once, right off the template, so BuildRow's "Failed"
        -- status (see the Status column) can switch cell.text to a bold-ish
        -- THICKOUTLINE font and this always has an unmutated original to
        -- restore back to on the cell's next reuse, below.
        cell.text.baseFontFile, cell.text.baseFontSize, cell.text.baseFontFlags = cell.text:GetFont()
        -- Name column's "[TBC]"-style expansion suffix (see BuildRow) - a
        -- separate FontString rather than appended to cell.text's own
        -- string, since a single FontString can't mix font sizes and this
        -- needs to render smaller than the name text next to it.
        cell.suffix = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cell.suffix:SetWordWrap(false)
        container.cellPool[n] = cell
    end

    cell:SetParent(parent)
    cell:ClearAllPoints()
    cell:Show()
    cell.bg:Hide()
    cell.icon:ClearAllPoints()
    cell.icon:Hide()
    cell.text:SetTextColor(TEXT_COLOR_DEFAULT[1], TEXT_COLOR_DEFAULT[2], TEXT_COLOR_DEFAULT[3])
    cell.text:SetFont(cell.text.baseFontFile, cell.text.baseFontSize, cell.text.baseFontFlags)
    cell.text:SetPoint("LEFT", PADDING, 0)
    cell.suffix:ClearAllPoints()
    cell.suffix:Hide()
    -- Reset any item-link hover/click behavior a previous use of this pooled
    -- cell may have wired up (see BuildRow) - cleared here, opted back into
    -- per-cell by whichever caller actually needs it this build. pendingItemId
    -- invalidates any in-flight ContinueOnItemLoad callback still targeting
    -- this cell from a previous use.
    cell:EnableMouse(false)
    cell:SetScript("OnEnter", nil)
    cell:SetScript("OnLeave", nil)
    cell:SetScript("OnMouseUp", nil)
    cell.pendingItemId = nil
    return cell
end

-- Returns the next reusable info-tooltip icon from `container`'s info-icon
-- pool (creating one if needed), parented under `parent`. Used by a header
-- column's optional `col.info` text (see DataTable:Build's header loop) -
-- pooled the same way as AcquireRow/AcquireCell rather than created fresh
-- per build, since DataTable:Build can now run often (e.g. DungeonEntry's
-- live quest-event refresh) and a plain CreateFrame call per build would
-- leak a new frame every time. `container.infoIconsUsed` must be reset to 0
-- at the start of a build.
local function AcquireInfoIcon(container, parent)
    container.infoIconPool = container.infoIconPool or {}
    container.infoIconsUsed = container.infoIconsUsed + 1
    local n = container.infoIconsUsed

    local icon = container.infoIconPool[n]
    if not icon then
        icon = CreateFrame("Frame", nil, parent)
        icon:SetSize(INFO_ICON_SIZE, INFO_ICON_SIZE)
        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints(icon)
        icon.texture:SetTexture(INFO_ICON_TEXTURE)
        container.infoIconPool[n] = icon
    end

    icon:SetParent(parent)
    icon:ClearAllPoints()
    icon:Show()
    icon:EnableMouse(true)
    return icon
end

-- Sizes a cell acquired via AcquireCell and (re)draws its border. Pass
-- skipTop/skipLeft to omit those edges (e.g. for the table's first cell).
local function LayoutCell(cell, width, height, skipTop, skipLeft)
    cell:SetSize(width, height)

    -- cell.text is anchored via LEFT+RIGHT points (see AcquireCell), so its
    -- word-wrap boundary is only ever implied by cell's own rendered width -
    -- which, right after SetSize above, hasn't necessarily propagated yet
    -- (frame geometry changes can take a frame to settle). Giving it this
    -- width explicitly makes the wrap boundary apply immediately instead of
    -- only after something else later forces a layout pass (e.g. building
    -- another DataTable, or resizing the window).
    cell.text:SetWidth(math.max(width - 2 * PADDING, 0))

    local t = BORDER_THICKNESS

    cell.edgeTop:ClearAllPoints()
    if skipTop then
        cell.edgeTop:Hide()
    else
        cell.edgeTop:Show()
        cell.edgeTop:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
        cell.edgeTop:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)
        cell.edgeTop:SetHeight(t)
    end

    cell.edgeBottom:ClearAllPoints()
    cell.edgeBottom:Show()
    cell.edgeBottom:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 0, 0)
    cell.edgeBottom:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)
    cell.edgeBottom:SetHeight(t)

    cell.edgeLeft:ClearAllPoints()
    if skipLeft then
        cell.edgeLeft:Hide()
    else
        cell.edgeLeft:Show()
        cell.edgeLeft:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
        cell.edgeLeft:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 0, 0)
        cell.edgeLeft:SetWidth(t)
    end

    cell.edgeRight:ClearAllPoints()
    cell.edgeRight:Show()
    cell.edgeRight:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)
    cell.edgeRight:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)
    cell.edgeRight:SetWidth(t)
end

-- Resolves `itemId` asynchronously and, once loaded, turns `cell` into an
-- icon + item-link-aware cell: shows the item's icon to the left of the
-- text, and wires GameTooltip:SetHyperlink on hover and ChatEdit_InsertLink
-- on shift-click. `displayText`, if given, is shown as the cell's text once
-- the item loads instead of the item's own link text (used by the Name
-- column to keep showing the row's custom Name string, e.g. "Copper",
-- rather than the item's real link label). Leave nil to show the raw item
-- link text.
--
-- GetItemInfo/GetItemLink can return nothing on the very first query for an
-- item the client hasn't cached yet, so ContinueOnItemLoad's callback fires
-- immediately if already cached, or once the data arrives otherwise. Cells
-- are pooled/reused across rebuilds (switching tabs/expansions), so
-- cell.pendingItemId guards against a delayed callback overwriting a cell
-- that's since been recycled for something unrelated.
--
-- An itemId this client's item database doesn't recognize at all (e.g. a
-- TBC-only item shown while running on the Classic Era client, now that the
-- expansion dropdown offers TBC there too) doesn't fail gracefully -
-- ContinueOnItemLoad throws deep inside Blizzard's own async callback
-- system ("table index is nil" in Blizzard_ObjectAPI's GetOrCreateCallbacks)
-- instead of just not calling back. pcall keeps that from surfacing as a
-- visible Lua error; the cell just keeps its plain displayText with no
-- icon/tooltip in that case, same as a row with no ItemLinkId at all.
local function WireItemCell(cell, itemId, displayText)
    cell.pendingItemId = itemId

    local item = Item:CreateFromItemID(itemId)
    if item:IsItemEmpty() then
        return
    end

    pcall(item.ContinueOnItemLoad, item, function()
        if cell.pendingItemId ~= itemId then
            return
        end
        local itemLink = item:GetItemLink()

        cell.icon:SetTexture(item:GetItemIcon())
        cell.icon:SetPoint("LEFT", PADDING, 0)
        cell.icon:Show()
        cell.text:ClearAllPoints()
        cell.text:SetPoint("LEFT", cell.icon, "RIGHT", ICON_TEXT_GAP, 0)
        cell.text:SetPoint("RIGHT", -PADDING, 0)
        cell.text:SetText(displayText or itemLink)

        cell:EnableMouse(true)
        cell:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        cell:SetScript("OnMouseUp", function()
            if IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(itemLink)
            end
        end)
    end)
end

-- Resolves `questId` into a real quest hyperlink where possible (falls back
-- to a manually-built "quest:id:level" link, in the same hyperlink format,
-- if the client doesn't have the quest's title cached yet), and turns `cell`
-- into a link-aware cell: wires GameTooltip:SetHyperlink on hover and
-- ChatEdit_InsertLink on shift-click - the quest-link counterpart to
-- WireItemCell above. Unlike items, a quest's link text resolves
-- synchronously (no item cache / ContinueOnItemLoad-style async load to wait
-- on), so this wires everything up immediately rather than deferring to a
-- callback. `displayText`, if given, is shown instead of the link's own
-- bracketed title text (mirrors WireItemCell's `displayText`).
local function WireQuestCell(cell, questId, level, displayText)
    local questLink = (GetQuestLink and GetQuestLink(questId))
        or ("|cffffff00|Hquest:%d:%d|h[%s]|h|r"):format(questId, level or 0, displayText or ("Quest " .. questId))

    cell.text:SetText(displayText or questLink)
    -- displayText (the row's own Name string) has no color codes of its own,
    -- unlike questLink's raw text - without this it'd read as plain white
    -- text with no visual sign it's a clickable/hoverable link. Standard
    -- WoW quest-hyperlink yellow (matches the |cffffff00 used above).
    cell.text:SetTextColor(1, 1, 0)

    cell:EnableMouse(true)
    cell:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(questLink)
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    cell:SetScript("OnMouseUp", function()
        if IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(questLink)
        end
    end)
end

-- Build one row's cells directly under `container`, anchored at a fixed
-- vertical offset. The table is sized to fit all of them (the page around it
-- scrolls). `rowHeight` overrides the default ROW_HEIGHT (see DataTable:Build).
local function BuildRow(container, row, columns, yOffset, skill, rowHeight)
    local frame = AcquireRow(container, container)
    frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
    frame:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, yOffset)
    frame:SetHeight(rowHeight)

    -- The first (id/name) column borrows the skill-diff color of the first
    -- other column that has a number in this row, so its color reflects this
    -- row's status at a glance without needing to look further right. Grey
    -- if none of the other columns have a number for this row.
    local nameColor
    if skill then
        local firstValue
        for i = 2, #columns do
            local value = row[columns[i].id]
            if type(value) == "number" then
                firstValue = value
                break
            end
        end
        nameColor = firstValue and SkillDiffColor(skill - firstValue) or SKILL_DIFF_GREY
    end

    for i, col in ipairs(columns) do
        local cell = AcquireCell(container, frame)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", col._x, 0)
        LayoutCell(cell, col.width, rowHeight)

        local value = row[col.id]
        cell.text:SetJustifyH(col.justify or "LEFT")

        if i == 1 then
            -- Name column: always display the row's own Name string (never
            -- the item's/quest's own link text), and keep the skill-diff
            -- tint. When this row also has an ItemLinkId, additionally show
            -- that item's icon and wire up tooltip/shift-click-to-chat via
            -- WireItemCell, pinning `value` as the text so it keeps reading
            -- e.g. "Copper" instead of switching to the item's own link
            -- label once loaded. QuestLinkId is the same idea for a quest
            -- hyperlink instead (see WireQuestCell) - mutually exclusive
            -- with ItemLinkId.
            local text = value or ""
            cell.text:SetText(text)
            if nameColor then
                cell.text:SetTextColor(nameColor[1], nameColor[2], nameColor[3])
            end
            if row.ItemLinkId then
                WireItemCell(cell, row.ItemLinkId, text)
            elseif row.QuestLinkId then
                WireQuestCell(cell, row.QuestLinkId, row.QuestLevel, text)
            end

            -- If this row wasn't introduced in Classic, append its expansion
            -- in brackets (e.g. "[TBC]") as a separate, smaller, deep-pink
            -- FontString right after the name text - a single FontString
            -- can't mix font sizes, so this can't just be appended to
            -- cell.text's own string. Anchored off cell.text's own rendered
            -- width (measured fresh here, right after SetText above) so it
            -- sits immediately after the name regardless of length. Nothing
            -- here needs to change for later expansions - GetExpansionName
            -- already has their names.
            if row.Introduced and row.Introduced ~= LE_EXPANSION_CLASSIC then
                cell.suffix:SetText(" [" .. Functions_General:GetExpansionName(row.Introduced) .. "]")
                cell.suffix:SetTextColor(EXPANSION_SUFFIX_COLOR[1], EXPANSION_SUFFIX_COLOR[2], EXPANSION_SUFFIX_COLOR[3])
                local fontFile, fontSize, fontFlags = cell.text:GetFont()
                cell.suffix:SetFont(fontFile, math.max((fontSize or 10) + EXPANSION_SUFFIX_FONT_SIZE_DELTA, 6), fontFlags)
                cell.suffix:ClearAllPoints()
                cell.suffix:SetPoint("LEFT", cell.text, "LEFT", cell.text:GetStringWidth() + 2, 0)
                cell.suffix:Show()
            end
        elseif col.id == "Status" then
            -- Not a data field (no row ever sets row.Status) - derived here at
            -- render time from row.QuestLinkId: green check if already
            -- completed (fast saved-variable check first, falling back to a
            -- live API check that also persists the result - see
            -- Functions_Quests), bold orange "Failed" if it's in the quest
            -- log but failed, "Accepted" text if it's in the quest log and
            -- neither completed nor failed, red X otherwise. Skipped
            -- entirely (no quest-log/completion API calls at all) for a row
            -- whose Faction rules out this character - e.g. an Alliance
            -- character looking at a Horde-only or Warlock-only quest -
            -- which shows red "Ineligible" instead.
            if not Functions_Quests:IsFactionEligible(row.Faction) then
                cell.text:SetJustifyH("CENTER")
                cell.text:SetText("Ineligible")
                local color = Functions_Quests.StatusColors.Ineligible
                cell.text:SetTextColor(color[1], color[2], color[3])
            else
                local questId = row.QuestLinkId
                local isDone = questId and (Functions_Quests:IsQuestMarkedComplete(questId)
                    or Functions_Quests:CheckAndSaveQuestCompletion(questId))

                if isDone then
                    cell.text:SetText("")
                    cell.icon:SetTexture(Functions_Quests.StatusIcons.Completed)
                    cell.icon:SetPoint("CENTER", 0, 0)
                    cell.icon:Show()
                elseif questId and Functions_Quests:IsQuestAccepted(questId) then
                    cell.text:SetJustifyH("CENTER")
                    if Functions_Quests:IsQuestFailed(questId) then
                        cell.text:SetText("Failed")
                        local color = Functions_Quests.StatusColors.Failed
                        cell.text:SetTextColor(color[1], color[2], color[3])
                        cell.text:SetFont(cell.text.baseFontFile, cell.text.baseFontSize, "THICKOUTLINE")
                    else
                        cell.text:SetText("Accepted")
                    end
                else
                    cell.text:SetText("")
                    cell.icon:SetTexture(Functions_Quests.StatusIcons.NotStarted)
                    cell.icon:SetPoint("CENTER", 0, 0)
                    cell.icon:Show()
                end
            end
        else
            cell.text:SetText(value or "")

            -- col.background gives every cell in the column the same fixed
            -- color; col.valueColors instead looks the color up by this
            -- cell's own value (e.g. { Horde = {...}, Alliance = {...} } -
            -- a value with no entry, like a future "Both", just stays
            -- untinted). At most one applies per column in practice.
            local color = value ~= nil and col.background and CELL_BACKGROUND_COLORS[col.background]
            if not color and value ~= nil and col.valueColors then
                color = col.valueColors[value]
            end
            if color then
                cell.text:SetTextColor(color[1], color[2], color[3])
            end

            -- col.valueBackgrounds fills the cell's own background texture
            -- (rather than tinting its text) based on this cell's value -
            -- e.g. { Low = {0,1,0}, Medium = {1,1,0}, High = {1,0,0} }.
            -- AcquireCell hides cell.bg by default, so a value with no entry
            -- just stays unfilled.
            local bgColor = value ~= nil and col.valueBackgrounds and col.valueBackgrounds[value]
            if bgColor then
                cell.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.35)
                cell.bg:Show()
            end
        end
    end
end

-- Hidden FontString reused to measure text width for auto-sized columns
-- (see column.autoWidth below) without needing an actual rendered cell -
-- never shown, parented to UIParent since it isn't tied to any one table's
-- container. baseFontFile/Size/Flags are captured from GameFontNormalSmall
-- the first time this runs (the same template every cell.text/cell.suffix
-- uses) and reused for every later measurement.
local measureFontString
local baseFontFile, baseFontSize, baseFontFlags

-- Measures `text` as it would actually render: at the cell's base font by
-- default, or that font shifted by `sizeDelta` (e.g. the Name column's
-- expansion-suffix font, EXPANSION_SUFFIX_FONT_SIZE_DELTA smaller - mirrors
-- BuildRow's identical derivation off cell.text:GetFont()).
local function MeasureTextWidth(text, sizeDelta)
    if not measureFontString then
        measureFontString = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        baseFontFile, baseFontSize, baseFontFlags = measureFontString:GetFont()
    end
    measureFontString:SetFont(baseFontFile, math.max(baseFontSize + (sizeDelta or 0), 6), baseFontFlags)
    measureFontString:SetText(text)
    return measureFontString:GetStringWidth()
end

-- Build the table into an AceGUI SimpleGroup and return it. When
-- `selectedExpansion` is given, only columns with no `exp` (e.g. the id/name
-- column) or with `exp == selectedExpansion` are included - everything else
-- (and any row data only reachable through those columns) is left out
-- entirely, not just hidden. Rows with a numeric `Introduced` greater than
-- selectedExpansion are dropped the same way (rows with no `Introduced` are
-- always kept) - a plain `<=` comparison against LE_EXPANSION_* values, so it
-- needs no changes as later expansions are added.
function DataTable:Build(parent, options, selectedExpansion)
    options = options or {}
    local columns = options.columns or {}
    local rows = options.rows or {}

    if selectedExpansion then
        local filteredColumns = {}
        for _, col in ipairs(columns) do
            if not col.exp or col.exp == selectedExpansion then
                filteredColumns[#filteredColumns + 1] = col
            end
        end
        columns = filteredColumns

        local filteredRows = {}
        for _, row in ipairs(rows) do
            if not row.Introduced or row.Introduced <= selectedExpansion then
                filteredRows[#filteredRows + 1] = row
            end
        end
        rows = filteredRows
    end

    -- columns[1].autoWidth sizes the Name column to fit the widest of the
    -- rows it's actually about to show (post expansion-filtering above) -
    -- its name text, its icon if the row has an ItemLinkId, and its
    -- "[TBC]"-style expansion suffix if it has one (mirrors BuildRow's own
    -- i==1 layout) - instead of a fixed number that has to be revisited by
    -- hand whenever data changes. Recomputed on every Build call (not just
    -- when columns[1].width happens to be unset) since `rows` here is
    -- already filtered by whichever expansion is currently selected, so the
    -- column can and does resize when that selection changes. Only
    -- column[1] is handled this way - BuildRow's icon/suffix layout is
    -- specific to the Name column, so auto-sizing wouldn't mean the same
    -- thing for any other column.
    if columns[1] and columns[1].autoWidth then
        local maxWidth = 0
        for _, row in ipairs(rows) do
            local rowWidth = MeasureTextWidth(row.Name or "")
            if row.ItemLinkId then
                rowWidth = rowWidth + ICON_SIZE + ICON_TEXT_GAP
            end
            if row.Introduced and row.Introduced ~= LE_EXPANSION_CLASSIC then
                rowWidth = rowWidth + MeasureTextWidth(
                    " [" .. Functions_General:GetExpansionName(row.Introduced) .. "]",
                    EXPANSION_SUFFIX_FONT_SIZE_DELTA
                )
            end
            if rowWidth > maxWidth then
                maxWidth = rowWidth
            end
        end
        columns[1].width = maxWidth + 2 * PADDING
    end

    -- Precompute each column's left x-offset.
    local x = 0
    for _, col in ipairs(columns) do
        col.width = col.width or 80
        col._x = x
        x = x + col.width
    end
    local totalWidth = x

    local width = options.width or totalWidth
    local rowHeight = options.rowHeight or ROW_HEIGHT
    local height = HEADER_HEIGHT + (#rows * rowHeight)

    -- Container frame hosting header + rows. A dedicated widget type (see
    -- AceGUIWidget-FlamesDataTable.lua) - AceGUI pools widgets separately
    -- per registered type name, so this frame is never shared with (or
    -- polluted by) any other kind of widget in this addon, unlike the
    -- stock "SimpleGroup" every spacer/section/etc. also draws from. No
    -- defensive "hide whatever's already attached" cleanup is needed here
    -- as a result: the only thing that can ever be attached is our own
    -- pooled rows/cells (container.rowPool/cellPool below), which are
    -- already correctly shown/hidden by AcquireRow/AcquireCell and the
    -- hide-the-excess loop at the end of this function.
    local group = AceGUI:Create("FlamesDataTable")
    local container = group.frame
    group:SetWidth(width)
    group:SetHeight(height)

    -- Belt-and-suspenders: makes sure a released-while-expanded table's
    -- rows/cells are hidden immediately rather than relying solely on the
    -- next build's hide-the-excess loop to catch them.
    group.OnRelease = function(self)
        for _, frame in ipairs(self.frame.rowPool or {}) do
            frame:Hide()
        end
        for _, frame in ipairs(self.frame.cellPool or {}) do
            frame:Hide()
        end
        for _, frame in ipairs(self.frame.infoIconPool or {}) do
            frame:Hide()
        end
    end

    -- Reset this build's usage counters; AcquireRow/AcquireCell/AcquireInfoIcon
    -- reuse container.rowPool/cellPool/infoIconPool from a previous build of
    -- this (possibly recycled) container instead of creating fresh frames.
    container.rowsUsed = 0
    container.cellsUsed = 0
    container.infoIconsUsed = 0

    -- Header row. Consecutive columns sharing a `group` value are merged into
    -- one cell; other columns show column.title if provided, else
    -- column.name, else column.id (e.g. quest columns that only ever set
    -- `id`/`width`, with no separate display-name field).
    local header = AcquireRow(container, container)
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    header.bg:SetAllPoints(header)
    header.bg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    header.bg:Show()

    local i = 1
    while i <= #columns do
        local col = columns[i]
        local cellWidth = col.width
        local label = col.title or col.name or col.id
        local justify = col.justify or "LEFT"

        if col.group then
            local last = i
            while columns[last + 1] and columns[last + 1].group == col.group do
                last = last + 1
            end
            cellWidth = (columns[last]._x + columns[last].width) - col._x
            label = col.group
            justify = "CENTER"
            i = last
        end

        local cell = AcquireCell(container, header)
        cell:SetPoint("TOPLEFT", header, "TOPLEFT", col._x, 0)
        -- The table's very first cell (top-left corner) omits its top/left
        -- edges so it doesn't double up against the surrounding page chrome.
        LayoutCell(cell, cellWidth, HEADER_HEIGHT, i == 1, i == 1)
        cell.text:SetJustifyH(justify)
        cell.text:SetText(label or "")

        -- Optional `col.info` (e.g. QuestColumns' Status/Effort columns in
        -- DungeonQuestData.lua): a small "(i)" icon at the cell's right edge
        -- that shows col.info as a GameTooltip on hover, nothing otherwise.
        -- col.info is an array of strings, one per tooltip line (typically a
        -- legend of the column's possible values) - each may embed WoW color
        -- escape codes (see Functions_General:ColorizeText) to render part of
        -- the line in a specific color; AddLine's own r,g,b just sets the
        -- default for whatever isn't already colored that way. wrap=false so
        -- the tooltip frame widens to fit the longest line instead of
        -- wrapping every line at some fixed width - these are short legend
        -- lines meant to read as one line each, not paragraphs.
        -- cell.text is narrowed so the label can't run under the icon.
        if col.info then
            cell.text:SetWidth(math.max(cellWidth - 2 * PADDING - INFO_ICON_SIZE - ICON_TEXT_GAP, 0))

            local infoIcon = AcquireInfoIcon(container, header)
            infoIcon:SetPoint("RIGHT", cell, "RIGHT", -PADDING, 0)
            infoIcon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(label or col.id)
                for _, line in ipairs(col.info) do
                    GameTooltip:AddLine(line, 1, 1, 1, false)
                end
                GameTooltip:Show()
            end)
            infoIcon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end

        i = i + 1
    end

    -- When `profession` is given and the character has it, numeric cells are
    -- colorized by (skill - cellValue) via SkillDiffColor. Otherwise untouched.
    local skill = options.profession and Functions_Professions:GetProfessionSkillNumber(options.profession)

    -- Rows, stacked directly below the header. No inner scrollbar: the page
    -- around this table already scrolls, so the table is just as tall as its data.
    for idx, row in ipairs(rows) do
        BuildRow(container, row, columns, -(HEADER_HEIGHT + (idx - 1) * rowHeight), skill, rowHeight)
    end

    -- Hide any pooled rows/cells left over from a build with more rows or
    -- columns than this one (e.g. switching from Mining to the smaller
    -- Herbalism table in the same recycled container).
    for n = container.rowsUsed + 1, #container.rowPool do
        container.rowPool[n]:Hide()
    end
    for n = container.cellsUsed + 1, #container.cellPool do
        container.cellPool[n]:Hide()
    end
    for n = container.infoIconsUsed + 1, #(container.infoIconPool or {}) do
        container.infoIconPool[n]:Hide()
    end

    return group
end
