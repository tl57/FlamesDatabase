DungeonInfo = {}

local ROW_HEIGHT = 14

-- Extra gap after each top-level header row (Zone ID, Mob Levels, Boss
-- Levels), so they read as distinct sections rather than a single block.
local HEADER_SPACING = 4

-- Boss-row left margins (see BuildInfoContent): bosses without a wing are
-- indented once; bosses grouped under a wing header are indented one level
-- deeper than the wing header itself.
local NO_WING_INDENT = 20
local WING_INDENT = 20
local BOSS_INDENT = 40

-- Text colors for BuildInfoContent's section/wing headers (see ColorizeText).
local HEADER_COLOR = { 1, 1, 0 }
local WING_COLOR = { 0, 1, 0 }

local INFO_CONTENT_WIDTH = 700

-- Build and return the content widget (zone id, mob levels, one row per
-- boss) for `dungeon`.
local function BuildInfoContent(dungeon)
    local group = Functions_Ace:CreateGroup()
    group:SetLayout("List")
    group:SetWidth(INFO_CONTENT_WIDTH)
    -- The rows below are pooled raw FontStrings, not real AceGUI children of
    -- `group` (see AddInfoRow) - so besides the spacer, group.children stays
    -- empty, and without this, AceGUI's own auto-height logic would
    -- recompute group's height from that near-empty list and reset it to 0
    -- (see DataTable.lua's identical use of SetAutoAdjustHeight(false), for
    -- the same reason).
    group:SetAutoAdjustHeight(false)

    -- List still positions this one real child at content's TOPLEFT despite
    -- SetAutoAdjustHeight(false) above - that only skips the final
    -- self:SetHeight call, which group:SetHeight(y) below overrides anyway.
    local spacer = GeneralUI:BuildSpacer()
    group:AddChild(spacer)

    local content = group.content
    -- Defensive: this exact frame may have previously been recycled by
    -- some other widget (e.g. DataTable.lua's own defensive "hide every
    -- leftover child" cleanup used to sweep up .content along with its
    -- pooled rows/cells, permanently hiding it since nothing else ever
    -- showed it back - fixed at the source, but re-asserting this costs
    -- nothing and guards against any other code with the same mistake).
    content:Show()
    content.rowsUsed = 0

    -- Rows are positioned relative to `content`'s top, so the first one
    -- starts below the spacer rather than at y=0.
    local y = spacer.frame.height
    local zoneIdHeader = Functions_General:ColorizeText("Zone ID:", HEADER_COLOR)
    local mobLevelsHeader = Functions_General:ColorizeText("Mob Levels:", HEADER_COLOR)
    local bossLevelsHeader = Functions_General:ColorizeText("Boss Levels:", HEADER_COLOR)

    y = GeneralUI:AddDungeonInfoRow(content, ("%s %s"):format(zoneIdHeader, dungeon.zoneid or "?"), y, ROW_HEIGHT) + HEADER_SPACING
    y = GeneralUI:AddDungeonInfoRow(content, ("%s %s-%s"):format(mobLevelsHeader, dungeon.minMobLevel or "?", dungeon.maxMobLevel or "?"), y, ROW_HEIGHT) + HEADER_SPACING

    y = GeneralUI:AddDungeonInfoRow(content, bossLevelsHeader, y, ROW_HEIGHT)
    -- Bosses with a `wing` field get a WING_INDENT header whenever the wing
    -- changes, with bosses under it at BOSS_INDENT; wing entries are assumed
    -- contiguous, in DungeonInfoData's own order. Bosses without a `wing`
    -- are listed flat at NO_WING_INDENT.
    local currentWing = nil
    for _, boss in ipairs(dungeon.bosses or {}) do
        if boss.wing then
            if boss.wing ~= currentWing then
                currentWing = boss.wing
                local wingHeader = Functions_General:ColorizeText(("%s:"):format(boss.wing), WING_COLOR)
                y = GeneralUI:AddDungeonInfoRow(content, wingHeader, y, ROW_HEIGHT, WING_INDENT)
            end
            y = GeneralUI:AddDungeonInfoRow(content, ("%s: %s"):format(boss.name, boss.level), y, ROW_HEIGHT, BOSS_INDENT)
        else
            y = GeneralUI:AddDungeonInfoRow(content, ("%s: %s"):format(boss.name, boss.level), y, ROW_HEIGHT, NO_WING_INDENT)
        end
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

-- Matches DungeonEntry.lua's DUNGEON_DROPDOWN_WIDTH (its own dungeon-picker
-- dropdown, floor(250 * 2 / 3)), so both pages' dungeon dropdowns look alike.
local DROPDOWN_WIDTH = 166

-- Build and return the content widget for the "Dungeon Info" page: a
-- dungeon-picker Dropdown (see DungeonEntry.lua's identical pattern)
-- followed by the selected dungeon's info, rebuilt in place whenever the
-- selection changes. Returns the AceGUI widget (so the page builder can
-- return it directly).
function DungeonInfo:Build(parent)
    local scroll = Functions_Ace:CreateScrollFrame()
    scroll:SetLayout("List")

    local names = {}
    for i, dungeon in ipairs(DungeonInfoData) do
        names[i] = dungeon.name
    end

    -- Replaced in place (see SelectDungeon) whenever the dropdown's
    -- selected dungeon changes, rather than rebuilding the whole page.
    local contentWidget

    local function SelectDungeon(index)
        if contentWidget then
            for idx, child in ipairs(scroll.children) do
                if child == contentWidget then
                    table.remove(scroll.children, idx)
                    break
                end
            end
            Functions_Ace:ReleaseWidget(contentWidget)
        end
        contentWidget = BuildInfoContent(DungeonInfoData[index])
        scroll:AddChild(contentWidget)
    end

    -- A Flow-layout row (mirrors GatheringPage.lua's BuildExpansionRadioGroup)
    -- rather than Dropdown's own SetLabel, which stacks the label above the
    -- control instead of beside it.
    local label = Functions_Ace:CreateLabel()
    label:SetFontObject(GameFontHighlightLarge)
    label:SetText("Dungeon:")
    local labelWidth = math.ceil(label.label:GetStringWidth()) + 8
    label:SetWidth(labelWidth)

    local dropdown = Functions_Ace:CreateDropdown()
    dropdown:SetWidth(DROPDOWN_WIDTH)
    dropdown:SetList(names)
    -- The Dropdown widget's selected-text FontString (self.text in
    -- AceGUIWidget-DropDown.lua) inherits UIDropDownMenuTemplate's default
    -- CENTER justify; left-align it to match every other label in this addon.
    dropdown.text:SetJustifyH("LEFT")
    dropdown:SetCallback("OnValueChanged", function(_, _, index)
        SelectDungeon(index)
    end)

    local row = Functions_Ace:CreateGroup()
    row:SetLayout("Flow")
    local totalWidth = labelWidth + DROPDOWN_WIDTH
    row:SetWidth(totalWidth)
    -- See BuildExpansionRadioGroup's identical line: Flow reads
    -- content.width directly, which SetWidth only updates asynchronously
    -- via the frame's OnSizeChanged - without this a group recycled from
    -- AceGUI's shared SimpleGroup pool can carry over a stale, narrower
    -- width and wrap the dropdown onto its own row.
    row.content.width = totalWidth
    row:AddChild(label)
    row:AddChild(dropdown)
    scroll:AddChild(row)

    dropdown:SetValue(1)
    SelectDungeon(1)

    return scroll
end
