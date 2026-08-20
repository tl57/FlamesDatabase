DungeonInfo = {}

local ROW_HEIGHT = 14

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
    y = GeneralUI:AddDungeonInfoRow(content, ("Zone ID: %s"):format(dungeon.zoneid or "?"), y, ROW_HEIGHT)
    y = GeneralUI:AddDungeonInfoRow(content, ("Mob Levels: %s-%s"):format(dungeon.minMobLevel or "?", dungeon.maxMobLevel or "?"), y, ROW_HEIGHT)

    y = GeneralUI:AddDungeonInfoRow(content, "Boss Levels:", y, ROW_HEIGHT)
    for _, boss in ipairs(dungeon.bosses or {}) do
        y = GeneralUI:AddDungeonInfoRow(content, ("%s: %s"):format(boss.name, boss.level), y, ROW_HEIGHT)
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

local DROPDOWN_WIDTH = 250

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
