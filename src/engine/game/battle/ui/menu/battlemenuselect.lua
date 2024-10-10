local BattleMenuSelect, super = Class(Object)

function BattleMenuSelect:init(ui, x, y)
    super.init(self, x or 30, y or 50)

    self.ui = ui
    self.battle = ui.battle

    self.current_x = 1
    self.current_y = 1

    self.columns = 2
    self.rows = 3

    self.h_separation = 230
    self.v_separation = 30

    self.info_x = 470
    self.info_y = 0

    self.items = {}

    self.textures = {
        ["heart"] = Assets.getTexture("player/heart"),
        ["arrow"] = Assets.getTexture("ui/page_arrow_down")
    }

    self.font = Assets.getFont("main")
end

-- Getters

function BattleMenuSelect:getTexture(texture)
    if self.textures[texture] then
        return self.textures[texture]
    end
end

function BattleMenuSelect:getCurrentItemIndex()
    return 2 * (self.current_y - 1) + self.current_x
end

function BattleMenuSelect:getCurrentItem()
    return self.items[self:getCurrentItemIndex()]
end

function BattleMenuSelect:getCurrentPage()
    return math.ceil(self.current_y / self.rows) - 1
end

function BattleMenuSelect:getCurrentMaxPages()
    return math.ceil(#self.items / (self.columns * self.rows)) - 1
end

function BattleMenuSelect:getCurrentPageOffset()
    return self:getCurrentPage() * (self.columns * self.rows)
end

function BattleMenuSelect:getCurrentMenuHeight()
    -- might not work
    return math.ceil(#self.items / self.columns)
end

function BattleMenuSelect:getCurrentMenuWidth()
    -- might not work
    return math.ceil(#self.items / self.rows)
end

function BattleMenuSelect:getIconsForItem(item)
    local icons = {}
    for _,icon in ipairs(item.icons) do
        if type(icon) == "string" then
            icon = {
                texture = icon,
                after_text = false,
                offset_x = 0,
                offset_y = 0,
                padding = nil
            }
        elseif type(icon) == "table" and Utils.isArray(icon) then
            icon = {
                texture = icon[1],
                after_text = icon[2] or false,
                offset_x = icon[3] or 0,
                offset_y = icon[4] or 0,
                padding = icon[5] or nil
            }
        else
            icon = {
                texture = icon.texture or nil,
                after_text = icon.after_text or false,
                offset_x = icon.offset_x or 0,
                offset_y = icon.offset_y or 0,
                padding = icon.padding or nil
            }
        end
        table.insert(icons, icon)
    end
    return icons
end

function BattleMenuSelect:getPartyIconsWidthForItem(item)
    return #item.party * 30 -- math.max(30, width)?
end

function BattleMenuSelect:getFrontIconsWidthForItem(item)
    local icons = self:getIconsForItem(item)
    local width = 0
    for _,icon in ipairs(icons) do
        if not icon.after_text then
            width = width + (icon.padding or Assets.getTexture(icon.texture):getWidth())
        end
    end
    return width
end

function BattleMenuSelect:getNameWidthForItem(item)
    return self.font:getWidth(item.name)
end

function BattleMenuSelect:getBackIconsWidthForItem(item)
    local icons = self:getIconsForItem(item)
    local width = 0
    for _,icon in ipairs(icons) do
        if icon.after_text then
            width = width + (icon.padding or Assets.getTexture(icon.texture):getWidth())
        end
    end
    return width
end

-- Functions

function BattleMenuSelect:resetPosition()
    self.current_x = 1
    self.current_y = 1
    self:refreshTensionPreview()
end

function BattleMenuSelect:addMenuSelectItem(item, extra)
    item = {
        ["name"]        = item.name        or "",
        ["data"]        = item.data        or nil,
        ["tp"]          = item.tp          or 0,
        ["description"] = item.description or "",
        ["color"]       = item.color       or PALETTE["battle_text"],
        ["party"]       = item.party       or {},
        ["icons"]       = item.icons       or {},
        ["callback"]    = item.callback    or function() end,
        ["highlight"]   = item.highlight   or nil,
        ["unusable"]    = item.unusable    or false
    }
    item = Utils.merge(item, extra or {})
    table.insert(self.items, item)
    return item
end

function BattleMenuSelect:clearMenuSelectItems()
    self.items = {}
end

function BattleMenuSelect:isCurrentPositionValid()
    if self:getCurrentItemIndex() > #self.items then
        return false
    end
    if (self.current_x > self.columns) or self.current_x < 1 then
        return false
    end
    return true
end

function BattleMenuSelect:canSelectItem(item)
    if item.unusable then
        return false
    end
    if item.tp and (item.tp > Game:getTension()) then
        return false
    end
    if item.party then
        -- do this better
        for _,party_id in ipairs(item.party) do
            local party_index = self.battle:getPartyIndex(party_id)
            local battler = self.battle.party[party_index]
            local action = self.battle.queued_actions[party_index]
            if (not battler) or (not battler:isActive()) or (action and action.cancellable == false) then
                -- They're either down, asleep, or don't exist. Either way, they're not here to do the action.
                return false
            end
        end
    end
    return true
end

function BattleMenuSelect:canSelectCurrentItem()
    return self:canSelectItem(self:getCurrentItem())
end

function BattleMenuSelect:isHighlighted(battler)
    local current_item = self:getCurrentItem()
    if current_item and current_item.highlight then
        local highlighted_battlers = current_item.highlight
        if isClass(highlighted_battlers) and highlighted_battlers:includes(Object) then
            return highlighted_battlers == battler
        elseif type(highlighted_battlers) == "table" then
            return Utils.containsValue(highlighted_battlers, battler)
        end
    else
        return false
    end
end

-- Draw

function BattleMenuSelect:drawMenu()
    self:drawCursor()
    self:drawItems()
    self:drawCurrentItemInfo()
    self:drawArrows()
end

function BattleMenuSelect:drawCursor()
    local soul_x = -25 + ((self.current_x - 1) * self.h_separation)
    local soul_y = -20 + ((self.current_y - (self:getCurrentPage() * self.rows)) * self.v_separation)
    Draw.setColor(self.battle.encounter:getSoulColor())
    Draw.draw(self:getTexture("heart"), soul_x, soul_y)
end

function BattleMenuSelect:drawItems()
    local page_offset = self:getCurrentPageOffset()

    local item_x = 0
    local item_y = 0

    for i = page_offset + 1, math.min(page_offset + (self.columns * self.rows), #self.items) do
        local x = item_x * self.h_separation
        local y = item_y * self.v_separation
        self:drawItem(self.items[i], x, y)

        if item_x < self.columns - 1 then
            item_x = item_x + 1
        else
            item_x = 0
            item_y = item_y + 1
        end
    end
end

function BattleMenuSelect:drawItem(item, x, y)
    self:drawPartyIcons(item, x, y)
    self:drawFrontIcons(item, x, y)
    self:drawItemName(item, x, y)
    self:drawBackIcons(item, x, y)
end

function BattleMenuSelect:drawPartyIcons(item, x, y)
    if self:canSelectItem(item) then
        Draw.setColor(PALETTE["battle_text"])
    else
        Draw.setColor(PALETTE["battle_text_unusable"])
    end

    local offset = 0
    for _,party_id in ipairs(item.party) do
        local chara = Game:getPartyMember(party_id)

        if self.battle:getPartyIndex(party_id) ~= self.battle.current_selecting_index then
            local ox, oy = chara:getHeadIconOffset()
            Draw.draw(Assets.getTexture(chara:getHeadIcons() .. "/head"), offset + (x + ox), y + oy)
            offset = offset + 30
        end
    end
end

function BattleMenuSelect:drawItemName(item, x, y)
    Draw.setFont(self.font)

    if self:canSelectItem(item) then
        Draw.setColor(item.color)
    else
        Draw.setColor(PALETTE["battle_text_unusable"])
    end

    local offset = self:getPartyIconsWidthForItem(item) + self:getFrontIconsWidthForItem(item)
    Draw.print(item.name, offset + x, y) 
end

function BattleMenuSelect:drawFrontIcons(item, x, y)
    local icons = self:getIconsForItem(item)
    for _,icon in ipairs(icons) do
        if not icon.after_text then
            if self:canSelectItem(item) then
                Draw.resetColor()
            else
                Draw.setColor(PALETTE["battle_invalid_icon"])
            end

            local offset = self:getPartyIconsWidthForItem(item)

            local texture = Assets.getTexture(icon.texture)
            local icon_x = (offset + x) + icon.offset_x
            local icon_y = y + icon.offset_y
    
            Draw.draw(texture, icon_x, icon_y)
        end
    end
end

function BattleMenuSelect:drawBackIcons(item, x, y)
    local icons = self:getIconsForItem(item)
    for _,icon in ipairs(icons) do
        if icon.after_text then
            if self:canSelectItem(item) then
                Draw.resetColor()
            else
                Draw.setColor(PALETTE["battle_invalid_icon"])
            end

            local offset = self:getFrontIconsWidthForItem(item) + self:getPartyIconsWidthForItem(item) + self:getNameWidthForItem(item)

            local texture = Assets.getTexture(icon.texture)
            local icon_x = (offset + x) + icon.offset_x
            local icon_y = y + icon.offset_y
    
            Draw.draw(texture, icon_x, icon_y)
        end
    end
end

function BattleMenuSelect:drawCurrentItemInfo()
    --split, somehow

    local current_item = self:getCurrentItem()
    if current_item then
        local tp_offset = 0, nil -- lua moment

        Draw.setColor(PALETTE["battle_description"])
        Draw.print(current_item.description, self.info_x, self.info_y)
        Draw.resetColor()
        _, tp_offset = current_item.description:gsub('\n', '\n')
        tp_offset = tp_offset + 1
    
        if current_item.tp and current_item.tp ~= 0 then
            Draw.setColor(PALETTE["battle_tension_description"])
            Draw.print(math.floor((current_item.tp / Game:getMaxTension()) * 100) .. "% "..Game:getConfig("tpName"), self.info_x, self.info_y + (tp_offset * 32))
        end
    end
end

function BattleMenuSelect:drawArrows()
    local page = self:getCurrentPage()
    local max_pages = self:getCurrentMaxPages()

    local texture = self:getTexture("arrow")
    local offset = (math.sin(Kristal.getTime() * 6) * 2)

    Draw.resetColor()
    if page > 0 then
        Draw.draw(texture, 470, 20 - offset, 0, 1, -1)
    end
    if page < max_pages then
        Draw.draw(texture, 470, 70 - offset)
    end
end

function BattleMenuSelect:draw()
    self:drawMenu()
    -- different function so hooks (for some reason if you use them) don't have to do a super call
    super.draw(self)
end

-- Input

function BattleMenuSelect:handleInput(key)
    local columns = self.columns
    local rows = self.rows

    if Input.isConfirm(key) then
        local result = self:select()
        if result then return end
    elseif Input.isCancel(key) then
        self:cancel()
        return
    elseif Input.is("left", key) then
        self.current_x = Utils.clampWrap(self.current_x - 1, 1, columns)
        if not self:isCurrentPositionValid() then self.current_x = 1 end
        self:onCursorMoved()
    elseif Input.is("right", key) then
        self.current_x = Utils.clampWrap(self.current_x + 1, 1, columns)
        if not self:isCurrentPositionValid() then self.current_x = 1 end
        self:onCursorMoved()
    end
    if Input.is("up", key) then
        self.current_y = math.max(1, self.current_y - 1)
        self:onCursorMoved()
    elseif Input.is("down", key) then
        local menu_height = self:getCurrentMenuHeight()
        local max_items = columns * rows

        if self:getCurrentItemIndex() % max_items == 0 and #self.items % max_items == 1 and self.current_y == (rows - 1) then
            self.current_x = self.current_x - 1
        end
        self.current_y = self.current_y + 1
        if (self.current_y > menu_height) or (not self:isCurrentPositionValid()) then
            self.current_y = menu_height
            if not self:isCurrentPositionValid() then
                self.current_y = menu_height - 1
            end
        end
        self:onCursorMoved()
    end
end

function BattleMenuSelect:onCursorMoved()
    self:refreshTensionPreview()
end

function BattleMenuSelect:refreshTensionPreview()
    local current_item = self:getCurrentItem()
    if current_item and current_item.tp then
        Game:setTensionPreview(current_item.tp)
    else
        Game:setTensionPreview(0)
    end
end

function BattleMenuSelect:select()
    -- eventify
    local item = self:getCurrentItem()
    if self:canSelectCurrentItem() then
        self.battle:stopAndPlaySound("ui_select")
        item.callback(item)
        return true
    end
end

function BattleMenuSelect:cancel()
    self.battle:stopAndPlaySound("ui_move")
    Game:setTensionPreview(0)
    self.battle:setState("ACTIONSELECT", "CANCEL")
end

function BattleMenuSelect:onKeyPressed(key)
    self:handleInput(key)
end

function BattleMenuSelect:canDeepCopy()
    return false
end

return BattleMenuSelect