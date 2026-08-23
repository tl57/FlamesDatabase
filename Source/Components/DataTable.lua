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

`options.rowHeight` overrides the default minimum row height (ROW_HEIGHT
below) for every row in this table - useful when a column's word-wrapped
text needs a taller row so its second line doesn't overlap the row border
below. It's a floor, not a fixed height: a row grows taller than it on its
own if any of its cells is list-valued (see below) and needs more room than
that to fit every entry (see ComputeRowHeight) - other rows in the same
table stay at the minimum.

A cell's row value can be an array of `{ icon = fileID/nil, text = string,
itemLink = string/nil }` entries instead of a plain string/number - rendered
as a vertically stacked list of icon+text sub-rows, each with its own
tooltip/shift-click-to-chat when `itemLink` is set (see AcquireSubRow). Lets
several items each get independent tooltip/click behavior within one cell,
which a single cell's own text/icon can't do (only the Name column's one
ItemLinkId gets that - see WireItemCell). The row automatically grows tall
enough to fit every entry (see ComputeRowHeight) - no need to precompute a
row height by hand. Used by Prospecting's multi-gem columns.

`column.mergeRepeats = true` merges consecutive rows that share that column's
exact value into one taller cell spanning all of them (Excel/Sheets-style
vertical cell merge) - shown once, vertically centered, instead of once per
row. Grouping is purely by consecutive equal values (`==`), independent per
column, so unrelated columns can merge along completely different
boundaries; other rows elsewhere in the table that happen to share a value
but aren't adjacent do NOT merge with each other. A merged cell's height is
the sum of its member rows' own heights (see ComputeRowHeight), not a
multiple of one - rows with taller list-valued cells elsewhere still
contribute their real height to the group. Used by Prospecting's Name/Skill
columns, which repeat identically across an ore's several gem-tier rows.

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
while still displaying the row's own Name text (see GeneralUI:WireItemCell).

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
    -- Hides any icon+text sub-rows a previous build may have shown on this
    -- pooled cell for a list-valued column (see AcquireSubRow/BuildRow) -
    -- without this, a cell recycled from a multi-gem-style column into a
    -- plain text/number column would still show its old sub-rows underneath.
    if cell.subRowPool then
        for _, subRow in ipairs(cell.subRowPool) do
            subRow:Hide()
        end
    end
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

local SUBROW_HEIGHT = 16
local SUBROW_ICON_SIZE = 14
local SUBROW_ICON_TEXT_GAP = 3

-- Returns `cell`'s Nth pooled icon+text sub-row (creating it if needed),
-- reset to a blank/hidden state. A cell whose row value is a list of
-- `{ icon, text, itemLink }` entries (see BuildRow) renders one of these per
-- entry instead of using the cell's own single text/icon - lets several
-- items each get their own tooltip/shift-click-to-chat within one cell,
-- which a single cell can't otherwise do (only the Name column's one
-- ItemLinkId gets that, via the cell's own icon/text - see WireItemCell).
-- Pooled per-cell (not per-container like AcquireRow/AcquireCell) since
-- sub-rows are only ever meaningful attached to the one cell that owns them.
local function AcquireSubRow(cell, n)
    cell.subRowPool = cell.subRowPool or {}
    local subRow = cell.subRowPool[n]
    if not subRow then
        subRow = CreateFrame("Frame", nil, cell)
        subRow.icon = subRow:CreateTexture(nil, "ARTWORK")
        subRow.icon:SetSize(SUBROW_ICON_SIZE, SUBROW_ICON_SIZE)
        subRow.icon:SetPoint("LEFT", 0, 0)
        subRow.text = subRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        subRow.text:SetPoint("LEFT", subRow.icon, "RIGHT", SUBROW_ICON_TEXT_GAP, 0)
        subRow.text:SetJustifyH("LEFT")
        cell.subRowPool[n] = subRow
    end

    subRow:ClearAllPoints()
    subRow:Show()
    subRow.icon:Hide()
    subRow:EnableMouse(false)
    subRow:SetScript("OnEnter", nil)
    subRow:SetScript("OnLeave", nil)
    subRow:SetScript("OnMouseUp", nil)
    return subRow
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

-- Resolves `questId` into a real quest hyperlink where possible (falls back
-- to a manually-built "quest:id:level" link, in the same hyperlink format,
-- if the client doesn't have the quest's title cached yet), and turns `cell`
-- into a link-aware cell: wires GameTooltip:SetHyperlink on hover and
-- ChatEdit_InsertLink on shift-click - the quest-link counterpart to
-- GeneralUI:WireItemCell above. Unlike items, a quest's link text resolves
-- synchronously (no item cache / ContinueOnItemLoad-style async load to wait
-- on), so this wires everything up immediately rather than deferring to a
-- callback. `displayText`, if given, is shown instead of the link's own
-- bracketed title text (mirrors GeneralUI:WireItemCell's `displayText`).
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

-- Hidden FontString reused to measure text width for auto-sized columns
-- (see column.autoWidth below) and gem-entry line-wrapping (see
-- LayoutGemEntries) without needing an actual rendered cell - never shown,
-- parented to UIParent since it isn't tied to any one table's container.
-- baseFontFile/Size/Flags are captured from GameFontNormalSmall the first
-- time this runs (the same template every cell.text/cell.suffix uses) and
-- reused for every later measurement.
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

local GEM_ENTRY_GAP = 10

-- Packs a list-valued cell's entries (see BuildRow) left-to-right, wrapping
-- to a new line only when the next entry wouldn't fit - several short gem
-- names share a line instead of each getting its own, the way a word-wrapped
-- paragraph flows, while a single entry too wide for the column still gets
-- its own line rather than overflowing sideways forever. Both BuildRow (to
-- position each entry) and ComputeRowHeight (to know how tall the cell needs
-- to be) call this with the same `value`/`columnWidth`, so they always agree
-- on the line count - cheap enough (a handful of entries per cell) that
-- recomputing per call beats threading a cached result between the two.
-- Returns parallel `line`/`x`/`width` arrays (1-based line number, left-edge
-- x offset from the cell's own left padding, and rendered pixel width, all
-- for entry i) plus the total line count.
local function LayoutGemEntries(value, columnWidth)
    local availWidth = math.max(columnWidth - 2 * PADDING, 0)
    local line, x, width = {}, {}, {}
    local lineCount = 1
    local cursor = 0
    for i, entry in ipairs(value) do
        local entryWidth = SUBROW_ICON_SIZE + SUBROW_ICON_TEXT_GAP + MeasureTextWidth(entry.text or "")
        if cursor > 0 then
            if cursor + GEM_ENTRY_GAP + entryWidth > availWidth then
                lineCount = lineCount + 1
                cursor = 0
            else
                cursor = cursor + GEM_ENTRY_GAP
            end
        end
        line[i] = lineCount
        x[i] = cursor
        width[i] = entryWidth
        cursor = cursor + entryWidth
    end
    return line, x, width, lineCount
end

-- Build one row's cells directly under `container`, anchored at a fixed
-- vertical offset. The table is sized to fit all of them (the page around it
-- scrolls). `rowHeight` overrides the default ROW_HEIGHT (see DataTable:Build).
-- `rowIdx`/`mergeStarts`/`mergeHeights` drive column.mergeRepeats (see
-- DataTable:Build): `mergeStarts[col.id][rowIdx]` is the row index this row's
-- merge group starts at for that column (itself, if this row IS the start),
-- and `mergeHeights[col.id][startIdx]` is that group's total height - a
-- merge-flagged column draws its cell (at the group's full height) only on
-- the group's first row, and is skipped entirely on every other row in the
-- group, since that first cell already visually covers them.
local function BuildRow(container, row, columns, yOffset, skill, rowHeight, rowIdx, mergeStarts, mergeHeights)
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
        nameColor = firstValue and Functions_Professions:GetSkillDiffColor(skill - firstValue) or Functions_Professions.SkillDiffGreyColor
    end

    for i, col in ipairs(columns) do
        -- A merge-flagged column only draws a cell on the first row of its
        -- group (see DataTable:Build's mergeStarts precompute) - every other
        -- row in that group is skipped entirely here, since the first row's
        -- cell is already sized (mergeHeights) to visually cover them.
        if not (col.mergeRepeats and mergeStarts[col.id][rowIdx] ~= rowIdx) then
        local cell = AcquireCell(container, frame)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", col._x, 0)
        local cellHeight = col.mergeRepeats and mergeHeights[col.id][rowIdx] or rowHeight
        LayoutCell(cell, col.width, cellHeight)

        local value = row[col.id]
        cell.text:SetJustifyH(col.justify or "LEFT")

        if i == 1 then
            -- Name column: always display the row's own Name string (never
            -- the item's/quest's own link text), and keep the skill-diff
            -- tint. When this row also has an ItemLinkId, additionally show
            -- that item's icon and wire up tooltip/shift-click-to-chat via
            -- GeneralUI:WireItemCell, pinning `value` as the text so it keeps reading
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
                GeneralUI:WireItemCell(cell, row.ItemLinkId, text, PADDING, ICON_TEXT_GAP)
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
        elseif type(value) == "table" then
            -- A list of { icon, text, itemLink } entries (see AcquireSubRow)
            -- instead of the usual plain string/number - one icon+text
            -- sub-row per entry, flowed left-to-right and wrapped onto
            -- further lines as needed (see LayoutGemEntries), each
            -- independently tooltip/shift-click-wired when it has an
            -- itemLink. Used by columns whose cells can hold several items
            -- at once (e.g. Prospecting's gem columns), which a single
            -- cell's own text/icon can't represent.
            cell.text:SetText("")
            local line, x, width = LayoutGemEntries(value, col.width)
            for n, entry in ipairs(value) do
                local subRow = AcquireSubRow(cell, n)
                subRow:SetPoint("TOPLEFT", cell, "TOPLEFT", PADDING + x[n], -(line[n] - 1) * SUBROW_HEIGHT)
                subRow:SetSize(width[n], SUBROW_HEIGHT)
                subRow.text:SetWidth(math.max(width[n] - SUBROW_ICON_SIZE - SUBROW_ICON_TEXT_GAP, 0))
                subRow.text:SetText(entry.text or "")
                if entry.icon then
                    subRow.icon:SetTexture(entry.icon)
                    subRow.icon:Show()
                end
                if entry.itemLink then
                    subRow:EnableMouse(true)
                    subRow:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetHyperlink(entry.itemLink)
                        GameTooltip:Show()
                    end)
                    subRow:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                    subRow:SetScript("OnMouseUp", function()
                        if IsModifiedClick("CHATLINK") then
                            ChatEdit_InsertLink(entry.itemLink)
                        end
                    end)
                end
            end
            for n = #value + 1, #(cell.subRowPool or {}) do
                cell.subRowPool[n]:Hide()
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
end

-- How tall `row` needs to be: `minHeight` (ROW_HEIGHT, or options.rowHeight
-- if the caller gave one - see DataTable:Build), or taller if any of its
-- cells is list-valued (see BuildRow) and needs more than that to fit every
-- entry - entries flow several-per-line (see LayoutGemEntries), so this is
-- however many *lines* that wraps to, at SUBROW_HEIGHT each, not one line
-- per entry. Each row gets exactly the height its own busiest cell needs
-- instead of every row in the table sharing one fixed height - e.g.
-- Prospecting's ore rows: Copper's 2-gem cell stays compact while Thorium's
-- 6-gem cell grows only itself.
local function ComputeRowHeight(row, columns, minHeight)
    local height = minHeight
    for _, col in ipairs(columns) do
        local value = row[col.id]
        if type(value) == "table" then
            local _, _, _, lineCount = LayoutGemEntries(value, col.width)
            local needed = lineCount * SUBROW_HEIGHT
            if needed > height then
                height = needed
            end
        end
    end
    return height
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
        -- Read via columns[1].id rather than hardcoding row.Name - every
        -- caller so far has named its id column "Name" (Mining, Herbalism,
        -- DungeonInfo, DungeonQuests all keep this identical), but
        -- ProspectingData.lua's id column is "colName", so this needs to be
        -- generic to work for both.
        for _, row in ipairs(rows) do
            local rowWidth = MeasureTextWidth(row[columns[1].id] or "")
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
    -- A floor, not a fixed height: each row gets exactly as tall as its own
    -- busiest cell needs (see ComputeRowHeight), never shorter than this.
    local minRowHeight = options.rowHeight or ROW_HEIGHT
    local rowHeights = {}
    local totalRowsHeight = 0
    for idx, row in ipairs(rows) do
        local h = ComputeRowHeight(row, columns, minRowHeight)
        rowHeights[idx] = h
        totalRowsHeight = totalRowsHeight + h
    end
    local height = HEADER_HEIGHT + totalRowsHeight

    -- column.mergeRepeats: consecutive rows sharing that column's exact
    -- value collapse into one taller cell (see BuildRow). mergeStarts[col.id]
    -- [idx] is the row index this row's merge group starts at (== idx if
    -- this row IS the start); mergeHeights[col.id][startIdx] is that group's
    -- total height - the sum of rowHeights across the group, not a multiple
    -- of one, since a group can mix rows of different heights (e.g.
    -- Prospecting's differently-sized gem-tier rows for one ore).
    local mergeStarts, mergeHeights = {}, {}
    for _, col in ipairs(columns) do
        if col.mergeRepeats then
            local starts, heights = {}, {}
            mergeStarts[col.id] = starts
            mergeHeights[col.id] = heights
            local idx = 1
            while idx <= #rows do
                local groupStart = idx
                local groupHeight = rowHeights[idx]
                local j = idx + 1
                while j <= #rows and rows[j][col.id] == rows[groupStart][col.id] do
                    groupHeight = groupHeight + rowHeights[j]
                    starts[j] = groupStart
                    j = j + 1
                end
                starts[groupStart] = groupStart
                heights[groupStart] = groupHeight
                idx = j
            end
        end
    end

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
    local group = Functions_Ace:CreateDataTableWidget()
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

    -- Rows, stacked directly below the header at their own individual
    -- heights (rowHeights, precomputed above) rather than one shared
    -- multiple of a fixed height. No inner scrollbar: the page around this
    -- table already scrolls, so the table is just as tall as its data.
    local yOffset = HEADER_HEIGHT
    for idx, row in ipairs(rows) do
        local h = rowHeights[idx]
        BuildRow(container, row, columns, -yOffset, skill, h, idx, mergeStarts, mergeHeights)
        yOffset = yOffset + h
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
