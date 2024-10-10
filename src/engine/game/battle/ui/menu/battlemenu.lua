local BattleMenu, super = Class(Object)

function BattleMenu:init()
    super.init(self)

    self.battle = Game.battle
    self.battle_ui = Game.battle.ui

    self.current_x = 0
    self.current_y = 0

    self.textures = {
        ["heart"]      = Assets.getTexture("player/heart"),
        ["arrow"]      = Assets.getTexture("ui/page_arrow_down"),
        ["spare_star"] = Assets.getTexture("ui/battle/sparestar"),
        ["tired_mark"] = Assets.getTexture("ui/battle/tiredmark"),
    } 

    self.font = Assets.getFont("main")

    self.menu_select = {
        x = 30,
        y = 50,

        h_spacing = 230,
        v_spacing = 30,

        columns = 2,
        rows = 3,

        items = {}
    }

    self.enemy_select = {
        x = 80,
        y = 50,

        spacing = 30,
        items_per_page = 3,

        enemies = self.battle.enemies,

        draw_mercy = Game:getConfig("mercyBar"),
        draw_percents = Game:getConfig("enemyBarPercentages")
    }

    self.party_select = {
        x = 80,
        y = 50,

        spacing = 30,
        items_per_page = 3,

        party = self.battle.party,
    }
end

--[[ function BattleMenu:getTexture(tex)
    if self.textures[tex] then
        return self.textures[tex]
    end
end

function BattleMenu:resetPosition()
    self.current_x = 1
    self.current_y = 1
end

function BattleMenu:isValidMenuSelectLocation()
    if self:getMenuSelectItemIndex() > #self.menu_select.items then
        return false
    end
    if (self.current_x > 2) or self.current_x < 1 then
        return false
    end
    return true
end

function BattleMenu:getCurrentMenuSelectItem()
    return self.menu_select.items[self:getMenuSelectItemIndex()]
end

function BattleMenu:getMenuSelectItemIndex()
    return 2 * (self.current_y - 1) + self.current_x
end

function BattleMenu:getCurrentMenuSelectPage()
    return math.ceil(self.current_y / self.menu_select.rows) - 1
end

function BattleMenu:getCurrentMenuSelectMaxPages()
    return math.ceil(#self.menu_select.items / (self.menu_select.columns * self.menu_select.rows)) - 1
end

function BattleMenu:getCurrentMenuSelectPageOffset()
    return self:getCurrentMenuSelectPage() * (self.menu_select.columns * self.menu_select.rows)
end ]]

--[[ function BattleMenu:addMenuSelectItem(item, extra)
    item = {
        ["name"]        = item.name or "",
        ["data"]        = item.data or nil,
        ["tp"]          = item.tp or 0,
        ["description"] = item.description or "",
        ["color"]       = item.color or COLORS.white,
        ["party"]       = item.party or {},
        ["icons"]       = item.icons or {},
        ["callback"]    = item.callback or function() end,
        ["highlight"]   = item.highlight or nil,
        ["unusable"]    = item.unusable or false
    }
    item = Utils.merge(item, extra or {})
    table.insert(self.menu_select.items, item)
    return item
end
 ]]
--[[ function BattleMenu:clearMenuSelectItems()
    self.menu_select.items = {}
end ]]

--[[ function BattleMenu:getCurrentEnemySelectPage()
    return math.ceil(self.current_y / self.enemy_select.items_per_page) - 1
end

function BattleMenu:getCurrentEnemySelectMaxPages()
    return math.ceil(#self.enemy_select.enemies / self.enemy_select.items_per_page) - 1
end

function BattleMenu:getCurrentEnemySelectPageOffset()
    return self:getCurrentEnemySelectPage() * self.enemy_select.items_per_page
end ]]

--[[ function BattleMenu:canSelectMenuSelectItem(item)
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
end ]]

function BattleMenu:drawMenu()
    --beforedraw event, cancellable
    local state = self.battle.state

    if state == "MENUSELECT" then
        self:drawMenuSelect()
    elseif state == "ENEMYSELECT" then
        self:drawEnemySelect()
    elseif state == "PARTYSELECT" then
        self:drawPartySelect()
    end

    --ondraw event
end

--[[ function BattleMenu:drawMenuSelect()
    self:drawMenuSelectCursor()
    self:drawMenuSelectItems()
    self:drawMenuSelectItemInfo()
    self:drawMenuSelectArrows()
end ]]

--[[ function BattleMenu:drawMenuSelectCursor()
    local soul_x = 5 + ((self.current_x - 1) * self.menu_select.h_spacing)
    local soul_y = 30 + ((self.current_y - (self:getCurrentMenuSelectPage() * self.menu_select.rows)) * self.menu_select.v_spacing)
    Draw.setColor(self.battle.encounter:getSoulColor())
    Draw.draw(self:getTexture("heart"), soul_x, soul_y)
end ]]

--[[ function BattleMenu:drawMenuSelectItems()
    local page_offset = self:getCurrentMenuSelectPageOffset()

    local item_x = 0
    local item_y = 0

    for i = page_offset + 1, math.min(page_offset + 6, #self.menu_select.items) do
        self:drawMenuSelectItem(self.menu_select.items[i], item_x, item_y)

        if item_x == 0 then
            item_x = 1
        else
            item_x = 0
            item_y = item_y + 1
        end
    end 
end]]

--[[ function BattleMenu:drawMenuSelectItem(item, x, y)
    if item then
        self:drawMenuSelectPartyIcons(item, x, y)
        self:drawMenuSelectFrontIcons(item, x, y)
        self:drawMenuSelectItemName(item, x, y)
        self:drawMenuSelectBackIcons(item, x, y)
    end
end ]]

--[[ function BattleMenu:getMenuSelectPartyIconsWidth(item)
    return #item.party * 30 -- math.max(30, width)?
end ]]

--[[ function BattleMenu:getMenuSelectFrontIconsWidth(item)
    local icons = self:getIconsForItem(item)
    local width = 0
    for _,icon in ipairs(icons) do
        if not icon.after_text then
            width = width + (icon.padding or icon.texture:getWidth())
        end
    end
    return width
end ]]
--[[ 
function BattleMenu:getMenuSelectNameWidth(item)
    return self.font:getWidth(item.name)
end ]]

--[[ function BattleMenu:getMenuSelectBackIconsWidth(item)
    local icons = self:getIconsForItem(item)
    local width = 0
    for _,icon in ipairs(icons) do
        if icon.after_text then
            width = width + (icon.padding or icon.texture:getWidth())
        end
    end
    return width
end ]]
--[[ 
function BattleMenu:drawMenuSelectItemName(item, x, y)
    Draw.setFont(self.font)

    if self:canSelectMenuSelectItem(item) then
        Draw.setColor(item.color)
    else
        Draw.setColor(COLORS.gray)
    end

    local offset = self:getMenuSelectPartyIconsWidth(item) + self:getMenuSelectFrontIconsWidth(item)
    Draw.print(item.name, (self.menu_select.x + offset) + (x * 230), (self.menu_select.y) + (y * 30)) 
end ]]

--[[ function BattleMenu:drawMenuSelectPartyIcons(item, x, y)
    if self:canSelectMenuSelectItem(item) then
        Draw.resetColor()
    else
        Draw.setColor(COLORS.gray)
    end

    local offset = 0
    for _,party_id in ipairs(item.party) do
        local chara = Game:getPartyMember(party_id)

        if self.battle:getPartyIndex(party_id) ~= self.battle.current_selecting_index then
            local ox, oy = chara:getHeadIconOffset()
            Draw.draw(Assets.getTexture(chara:getHeadIcons() .. "/head"), offset + 30 + (x * 230) + ox, 50 + (y * 30) + oy)
            offset = offset + 30
        end
    end
end ]]

--[[ function BattleMenu:getIconsForItem(item)
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
        elseif type(icon) == "table" and Utils.isArray(table) then
            -- genuinely don't know what the person who decided using an ordered
            -- list for this was thinking, keeping compatibility for it because why not
            icon = {
                texture = icon[1],
                after_text = icon[2] or false,
                offset_x = icon[3] or 0,
                offset_y = icon[4] or 0,
                padding = icon[5] or nil
            }
        end
        table.insert(icons, icon)
    end
    return icons
end ]]
--[[ 
function BattleMenu:drawMenuSelectFrontIcons(item, x, y)
    local icons = self:getIconsForItem(item)
    for _,icon in ipairs(icons) do
        if not icon.after_text then
            local texture = Assets.getTexture(icon.texture)
            local icon_x = text_offset + 30 + (x * 230) + (icon.offset_x or 0)
            local icon_y = 50 + (y * 30) + (icon.offset_y or 0)
    
            Draw.draw(texture, icon_x, icon_y)
            text_offset = text_offset + (icon.padding or texture:getWidth())
        end
    end
end ]]

--[[ function BattleMenu:drawMenuSelectBackIcons(item, x, y)
    local icons = self:getIconsForItem(item)
    for _,icon in ipairs(icons) do
        if icon.after_text then
            if item.can_select then
                Draw.resetColor()
            else
                -- palleteify
                Draw.setColor(COLORS.gray)
            end        

            local texture = Assets.getTexture(icon.texture)
            local icon_x = text_offset + 30 + (x * 230) + (icon.offset_x or 0)
            local icon_y = 50 + (y * 30) + (icon.offset_y or 0)
    
            Draw.draw(texture, icon_x, icon_y)
            text_offset = text_offset + (icon.padding or texture:getWidth())
        end
    end
end ]]

--[[ function BattleMenu:drawMenuSelectItemInfo()
    --split, somehow

    local current_item = self:getCurrentMenuSelectItem()
    local tp_offset = 0, nil -- lua moment

    Draw.setColor(COLORS.gray)
    Draw.print(current_item.description, 260 + 240, 50)
    Draw.resetColor()
    _, tp_offset = current_item.description:gsub('\n', '\n')
    tp_offset = tp_offset + 1

    if current_item.tp and current_item.tp ~= 0 then
        Draw.setColor(PALETTE["tension_desc"])
        Draw.print(math.floor((current_item.tp / Game:getMaxTension()) * 100) .. "% "..Game:getConfig("tpName"), 260 + 240, 50 + (tp_offset * 32))
        -- move these to onkeypressed, don't update every frame since menu items are static
       -- Game:setTensionPreview(current_item.tp)
    --else
       -- Game:setTensionPreview(0)
    end
end ]]
--[[ 
function BattleMenu:drawMenuSelectArrows()
    local page = self:getCurrentMenuSelectPage()
    local max_pages = self:getCurrentMenuSelectMaxPages()

    local texture = self:getTexture("arrow")
    local offset = (math.sin(Kristal.getTime() * 6) * 2)

    Draw.resetColor()
    if page < max_pages then
        Draw.draw(texture, 470, 120 + offset)
    end
    if page > 0 then
        Draw.draw(texture, 470, 70 - offset, 0, 1, -1)
    end
end ]]

function BattleMenu:drawEnemySelectHeaders()
    Draw.resetColor()
    Draw.setFont(self.font)
    -- put the positions in init
    if self.enemy_select.draw_mercy then
        if self.battle.state == "ENEMYSELECT" and self.battle.state_reason ~= "XACT" then
            Draw.print("HP", 424, 39, 0, 1, 0.5)
        end
        Draw.print("MERCY", 524, 39, 0, 1, 0.5)
    end
end

function BattleMenu:drawEnemySelect()
    self:drawEnemySelectCursor()
    self:drawEnemySelectHeaders()
    self:drawEnemySelectItems()
    self:drawEnemySelectArrows()
end

function BattleMenu:drawEnemySelectCursor()
    local page_offset = self:getCurrentEnemySelectPageOffset()

    local menu_x, menu_y, menu_spacing = self.enemy_select.x, self.enemy_select.y, self.enemy_select.spacing

    Draw.setColor(self.battle.encounter:getSoulColor())
    Draw.draw(self:getTexture("heart"), menu_x - 25, (menu_y - 20) + ((self.current_y - page_offset) * menu_spacing))
end

function BattleMenu:drawEnemySelectItems()
    local page_offset = self:getCurrentEnemySelectPageOffset()

    local menu_x, menu_y, menu_spacing = self.enemy_select.x, self.enemy_select.y, self.enemy_select.spacing

    for i = page_offset + 1, math.min(page_offset + 3, #self.enemy_select.enemies) do
        local y = menu_y + ((i - page_offset - 1) * menu_spacing)
        self:drawEnemyItem(menu_x, y, self.enemy_select.enemies[i])
    end
end

function BattleMenu:drawEnemyItem(x, y, enemy)
    if enemy then
        self:drawEnemyName(x, y, enemy)
        self:drawEnemyIcons(x, y, enemy)
        self:drawEnemyComment(x, y, enemy)
        self:drawEnemyGauges(x, y, enemy)
    end
end

function BattleMenu:drawEnemyName(x, y, enemy)
    local name_colors = enemy:getNameColors()
    if type(name_colors) ~= "table" then
        name_colors = {name_colors}
    end

    if #name_colors <= 1 then
        self:drawSingleColorEnemyName(x, y, enemy)
    else
        self:drawGradientEnemyName(x, y, enemy)
    end
end

function BattleMenu:drawSingleColorEnemyName(x, y, enemy)
    local name_colors = enemy:getNameColors()
    if type(name_colors) ~= "table" then
        name_colors = {name_colors}
    end

    Draw.setColor(name_colors[1] or (enemy.selectable and COLORS.white) or COLORS.gray)
    Draw.print(enemy.name, x, y)
end

function BattleMenu:drawGradientEnemyName(x, y, enemy)
    local name_colors = enemy:getNameColors()
    if type(name_colors) ~= "table" then
        name_colors = {name_colors}
    end

    Draw.resetColor()

    local canvas = Draw.pushCanvas(self.font:getWidth(enemy.name), self.font:getHeight())
        Draw.print(enemy.name)
    Draw.popCanvas()

    local color_canvas = Draw.pushCanvas(#name_colors, 1)
        for i = 1, #name_colors do
            Draw.setColor(name_colors[i])
            Draw.rectangle("fill", i - 1, 0, 1, 1)
        end
    Draw.popCanvas()

    Draw.resetColor()

    local shader = Kristal.Shaders["DynGradient"]
    Draw.setShader(shader)
    shader:send("colors", color_canvas)
    shader:send("colorSize", {#name_colors, 1})
    Draw.drawCanvas(canvas, x, y)
    Draw.setShader()
end

function BattleMenu:drawEnemyComment(x, y, enemy)
    local text_width = self.font:getWidth(enemy.name)
    Draw.setColor(PALETTE["battle_enemy_comment"])

    if (x + ((text_width + 60) + (self.font:getWidth(enemy.comment) / 2))) < 415 then
        Draw.print(enemy.comment, x + (text_width + 60), y)
    else
        Draw.print(enemy.comment, x + (text_width + 60), y, 0, 0.5, 1)
    end
end

function BattleMenu:drawEnemyIcons(x, y, enemy)
    -- ehhhhhh
    local spare_icon, tired_icon = self:drawDefaultEnemyIcons(x, y, enemy)
    self:drawCustomEnemyIcons(x, y, enemy, spare_icon, tired_icon)
end

function BattleMenu:drawDefaultEnemyIcons(x, y, enemy)
    local spare_icon = false
    local tired_icon = false

    local text_width = self.font:getWidth(enemy.name)

    Draw.resetColor()
    if enemy.tired and enemy:canSpare() then
        Draw.draw(self:getTexture("spare_star"), x + (text_width + 20), y + 10)
        Draw.draw(self:getTexture("tired_mark"), x + (text_width + 40), y + 10)
        spare_icon = true
        tired_icon = true
    elseif enemy.tired then
        Draw.draw(self:getTexture("tired_mark"), x + (text_width + 40), y + 10)
        tired_icon = true
    elseif enemy.mercy >= 100 then
        Draw.draw(self:getTexture("spare_star"), x + (text_width + 20), y + 10)
        spare_icon = true
    end

    return spare_icon, tired_icon
end

function BattleMenu:drawCustomEnemyIcons(x, y, enemy, spare_icon, tired_mark)
    local text_width = self.font:getWidth(enemy.name)

    Draw.resetColor()

    -- doesn't this not work?
    for i = 1, #enemy.icons do
        if enemy.icons[i] then
            if (spare_icon and (i == 1)) or (tired_icon and (i == 2)) then
                -- Skip custom icons if we're already drawing spare/tired ones
            else
                Draw.draw(enemy.icons[i], x + (text_width + (i * 20)), y + 10)
            end
        end
    end
end

function BattleMenu:drawEnemyGauges(x, y, enemy)
    self:drawEnemyHPGauge(x, y, enemy)
    self:drawEnemyMercyGauge(x, y, enemy)
end

function BattleMenu:drawEnemyHPGauge(x, y, enemy)
    if self.battle.state_reason ~= "XACT" then -- detect this better
        local hp_x = (self.enemy_select.draw_mercy and x + 340 or x + 430)
        local percent = enemy.health / enemy.max_health

        if enemy.selectable then
            Draw.setColor(PALETTE["action_health_bg"])
            Draw.rectangle("fill", hp_x, y + 5, 81, 16)

            Draw.setColor(PALETTE["action_health"])
            Draw.rectangle("fill", hp_x, y + 5, math.ceil(percent * 81), 16)

            if self.enemy_select.draw_percents then
                Draw.setColor(PALETTE["action_health_text"])
                Draw.print(math.ceil(percent * 100) .. "%", hp_x + 4, y + 5, 0, 1, 0.5)
            end
        end
    end
end

function BattleMenu:drawEnemyMercyGauge(x, y, enemy)
    if self.enemy_select.draw_mercy then
        -- split into separate functions for the normal, disabled, and unselectable gauges
        -- option to not change and/or draw the mercy gauge for unselectable enemies
        if enemy.selectable then
            Draw.setColor(PALETTE["battle_mercy_bg"])
        else
            Draw.setColor(PALETTE["battle_mercy_unselectable_bg"])
        end

        local gauge_x = x + 440
        local gauge_y = y + 5

        Draw.rectangle("fill", x + 440, y + 5, 81, 16)

        if enemy.disable_mercy then
            Draw.setColor(PALETTE["battle_mercy_text"])
            Draw.setLineWidth(2)
            Draw.line(gauge_x,  51 + gauge_y,           gauge_x + 81, (51 + gauge_y) + 16 - 1)
            Draw.line(gauge_x, (51 + gauge_y) + 16 - 1, 520 + 81,      51 + gauge_y)
        else
            Draw.setColor(PALETTE["battle_mercy_fill"])
            -- the unselectable mercy bar has a fucked up position in dr
            Draw.rectangle("fill", gauge_x, y + 5, ((enemy.mercy / 100) * 81), 16)

            if self.enemy_select.draw_percents and enemy.selectable then
                Draw.setColor(PALETTE["battle_mercy_text"])
                Draw.print(math.ceil(enemy.mercy) .. "%", gauge_x + 4, y + 5, 0, 1, 0.5)
            end
        end
    end
end

function BattleMenu:drawEnemySelectArrows()
    local page = self:getCurrentEnemySelectPage()
    local max_pages = self:getCurrentEnemySelectMaxPages()

    local arrow_texture = self:getTexture("arrow")
    local offset = math.sin(Kristal.getTime() * 6) * 2

    local menu_x, menu_y = self.enemy_select.x, self.enemy_select.y

    Draw.resetColor()
    if page > 0 then
        Draw.draw(arrow_texture, menu_x - 60, (menu_y + 20) - offset, 0, 1, -1)
    end
    if page < max_pages then
        Draw.draw(arrow_texture, menu_x - 60, (menu_y + 70) + offset)
    end
    -- probably won't work
end

function BattleMenu:drawPartySelect()
    self:drawPartySelectCursor()
    self:drawPartySelectItems()
end

function BattleMenu:drawPartySelectCursor()
    local page = math.ceil(self.current_y / 3) - 1
    local current_page = page * 3

    local menu_x, menu_y, menu_spacing = self.party_select.x, self.party_select.y, self.party_select.spacing

    Draw.setColor(self.battle.encounter:getSoulColor())
    Draw.draw(self:getTexture("heart"), menu_x - 25, (menu_y - 5) + ((self.current_y - current_page) * menu_spacing))
end

function BattleMenu:drawPartySelectItems()
    local party = self.battle.party

    local page = math.ceil(self.current_y / 3) - 1
    local max_page = math.ceil(#party / 3) - 1
    local current_page = page * 3

    local menu_x, menu_y, menu_spacing = self.party_select.x, self.party_select.y, self.party_select.spacing

    for i = current_page + 1, math.min(current_page + 3, #self.party_select.party) do
        local y = menu_y + ((i - current_page - 1) * menu_spacing)
        self:drawPartyItem(menu_x, y, party[i])
    end
end

function BattleMenu:drawPartyItem(x, y, member)
    if member then
        self:drawPartyName(x, y, member)
        self:drawPartyGauges(x, y, member)
    end
end

function BattleMenu:drawPartyName(x, y, member)
    Draw.resetColor()
    Draw.print(member.chara:getName(), x, y)
end

function BattleMenu:drawPartyGauges(x, y, member)
    self:drawPartyHPGauge(x, y, member)
end

function BattleMenu:drawPartyHPGauge(x, y, member)
    local chara = member.chara

    local gauge_x = x + 320
    local gauge_y = y + 5

    -- gauge width/height options?
    Draw.setColor(PALETTE["action_health_bg"])
    Draw.rectangle("fill", gauge_x, gauge_y, 101, 16)

    local percent = chara:getHealth() / chara:getStat("health")
    Draw.setColor(PALETTE["action_health"])
    Draw.rectangle("fill", gauge_x, gauge_y, math.ceil(percent * 101), 16)
end

function BattleMenu:handleMenuInput(key)
    -- eventify

    local state = self.battle.state

    if state == "MENUSELECT" then
        self:handleMenuSelectInput(key)
    elseif state == "ENEMYSELECT" then
        self:handleEnemySelectInput(key)
    elseif state == "PARTYSELECT" then
        self:handlePartySelectInput(key)
    end
end

--[[ function BattleMenu:handleMenuSelectInput(key)
    local menu = self.menu_select
    local columns = menu.columns
    local rows = menu.rows

    if Input.isConfirm(key) then
        local result = self:selectCurrentMenuSelectItem()
        if result then return end
    elseif Input.isCancel(key) then
        self:cancelMenuSelect()
        return
    elseif Input.is("left", key) then
        self.current_x = Utils.clampWrap(self.current_x - 1, 1, columns)
        if not self:isValidMenuSelectLocation() then self.current_x = 1 end
    elseif Input.is("right", key) then
        self.current_x = Utils.clampWrap(self.current_x + 1, 1, columns)
        if not self:isValidMenuSelectLocation() then self.current_x = 1 end
    end
    if Input.is("up", key) then
        self.current_y = math.max(1, self.current_y - 1)
    elseif Input.is("down", key) then
        local menu_height = math.ceil(#menu.items / 2)
        local max_items = columns * rows

        if self:getMenuSelectItemIndex() % max_items == 0 and #menu.items % max_items == 1 and self.current_y == (rows - 1) then
            self.current_x = self.current_x - 1
        end
        self.current_y = self.current_y + 1
        if (self.current_y > menu_height) or (not self:isValidMenuSelectLocation()) then
            self.current_y = menu_height
            if not self:isValidMenuSelectLocation() then
                self.current_y = menu_height - 1
            end
        end
    end
end ]]

--[[ function BattleMenu:selectCurrentMenuSelectItem()

end

function BattleMenu:cancelMenuSelect()
    self.battle:stopAndPlaySound("ui_move")
    self.battle:setState("ACTIONSELECT", "CANCEL")
end ]]

--[[ function BattleMenu:handleEnemySelectInput(key)
    local enemy_count = #self.battle.enemies

    if Input.isConfirm(key) then
        self:selectCurrentEnemy()
        return
    end
    if Input.isCancel(key) then
        self:cancelEnemySelect()
        return
    end
    if Input.is("up", key) then
        if enemy_count == 0 then return end
        local old_position = self.current_y
        local give_up = 0
        repeat
            give_up = give_up + 1
            if give_up >= 100 then return end
            self.current_y = Utils.clampWrap(self.current_y - 1, 1, enemy_count)
        until(self.battle.enemies[self.current_y] and self.battle.enemies[self.current_y].selectable) -- do this better

        if self.current_y ~= old_position then
            self.battle:stopAndPlaySound("ui_move")
        end
    end
    if Input.is("down", key) then
        if enemy_count == 0 then return end
        local old_position = self.current_y
        local give_up = 0
        repeat
            give_up = give_up + 1
            if give_up >= 100 then return end
            self.current_y = Utils.clampWrap(self.current_y + 1, 1, enemy_count)
        until(self.battle.enemies[self.current_y] and self.battle.enemies[self.current_y].selectable) -- do this better

        if self.current_y ~= old_position then
            self.battle:stopAndPlaySound("ui_move")
        end
    end
end ]]

--[[ function BattleMenu:selectCurrentEnemy()
    local battle = self.battle
    if battle.encounter:onEnemySelect(battle.state_reason, self.current_y) then return end
    if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemySelect, battle.state_reason, self.current_y) then return end
    battle:stopAndPlaySound("ui_select")
    if #battle.enemies == 0 then return end
    battle:clearMenuItems()

    if battle.state_reason == "ACT" then
        local enemy = self.enemy_select.enemies[self.current_y]
        enemy:addACTsToBattleMenu()
        if #self.menu_select.items > 0 then
            self.battle:setState("MENUSELECT", "ACT", {enemy = enemy})
        end
    else
        battle:nextParty()
    end
end ]]
--[[ 
function BattleMenu:cancelEnemySelect()
    local battle = self.battle
    if battle.encounter:onEnemyCancel(battle.state_reason, self.current_y) then return end
    if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemyCancel, battle.state_reason, self.current_y) then return end
    battle:stopAndPlaySound("ui_select")

    if battle.state_reason == "SPELL" then
        battle:setState("MENUSELECT", "SPELL")
    elseif battle.state_reason == "ITEM" then
        battle:setState("MENUSELECT", "ITEM")
    else
        battle:setState("ACTIONSELECT", "CANCEL")
    end
end ]]

--[[ function BattleMenu:handlePartySelectInput(key)
    local columns = 1
    local rows = #self.battle.party

    if Input.isConfirm(key) then
        self:selectCurrentParty()
        return
    end
    if Input.isCancel(key) then
        self:cancelPartySelect()
        return
    end
    if Input.is("up", key) then
        self.current_y = Utils.clampWrap(self.current_y - 1, 1, rows)
        self.battle:stopAndPlaySound("ui_move")
    end
    if Input.is("down", key) then
        self.current_y = Utils.clampWrap(self.current_y + 1, 1, rows)
        self.battle:stopAndPlaySound("ui_move")
    end
end
 ]]
function BattleMenu:selectCurrentParty()

end

function BattleMenu:cancelPartySelect()

end

function BattleMenu:draw()
    self:drawMenu()
    super.draw(self)
end

function BattleMenu:onKeyPressed(key)
    self:handleMenuInput(key)
end

function BattleMenu:canDeepCopy()
    return false
end

return BattleMenu