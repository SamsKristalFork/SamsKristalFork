local BattleEnemySelect, super = Class(Object)

function BattleEnemySelect:init(ui, x, y)
    super.init(self, x or 80, y or 50)

    self.ui = ui
    self.battle = ui.battle

    self.current_enemy = 1

    self.separation = 30
    self.items_per_page = 3

    self.enemies = self.battle.enemies
    self.all_enemies = self.battle.all_enemies
    self.enemy_list = self.battle.enemy_list

    self.draw_mercy = Game:getConfig("mercyBar")
    self.draw_percents = Game:getConfig("enemyBarPercentages")

    self.textures = {
        ["heart"]      = Assets.getTexture("player/heart"),
        ["arrow"]      = Assets.getTexture("ui/page_arrow_down"),
        ["spare_star"] = Assets.getTexture("ui/battle/sparestar"),
        ["tired_mark"] = Assets.getTexture("ui/battle/tiredmark"),
    }

    self.font = Assets.getFont("main")
end

-- Getters

function BattleEnemySelect:getTexture(texture)
    if self.textures[texture] then
        return self.textures[texture]
    end
end

function BattleEnemySelect:getCurrentEnemy()
    return self.all_enemies[self.current_enemy]
end

function BattleEnemySelect:getCurrentPage()
    return math.ceil(self.current_enemy / self.items_per_page) - 1
end

function BattleEnemySelect:getCurrentMaxPages()
    return math.ceil(#self.all_enemies / self.items_per_page) - 1
end

function BattleEnemySelect:getCurrentPageOffset()
    return self:getCurrentPage() * self.items_per_page
end

-- Functions

function BattleEnemySelect:canSelectEnemy(enemy)
    return Utils.containsValue(self.enemies, enemy) and enemy.selectable
end

function BattleEnemySelect:canSelectCurrentEnemy()
    return self:canSelectEnemy(self:getCurrentEnemy())
end

function BattleEnemySelect:resetPosition()
    local enemies = self.all_enemies

    self.current_enemy = 0
    local give_up = 0
    repeat
        give_up = give_up + 1
        if give_up == 100 then return end
        self.current_enemy = Utils.clampWrap(self.current_enemy + 1, 1, #enemies)
    until(enemies[self.current_enemy] and self:canSelectCurrentEnemy()) -- do this better
end

function BattleEnemySelect:isHighlighted(battler)
    return self:getCurrentEnemy() == battler
end

-- Draw

function BattleEnemySelect:drawMenu()
    self:drawCursor()
    self:drawHeaders()
    self:drawEnemies()
    self:drawArrows()
end

function BattleEnemySelect:drawCursor()
    local page_offset = self:getCurrentPageOffset()
    Draw.setColor(self.battle.encounter:getSoulColor())
    Draw.draw(self:getTexture("heart"), -25, -20 + ((self.current_enemy - page_offset) * self.separation))
end

function BattleEnemySelect:drawHeaders()
    Draw.resetColor()
    Draw.setFont(self.font)
    -- put the positions in init

    if not self.battle.state_vars["x-act"] then
        Draw.print("HP", 344, -11, 0, 1, 0.5)
    end
    if self.draw_mercy then
        Draw.print("MERCY", 444, -11, 0, 1, 0.5)
    end
end

function BattleEnemySelect:drawEnemies()
    local page_offset = self:getCurrentPageOffset()

    for i = page_offset + 1, math.min(page_offset + self.items_per_page, #self.all_enemies) do
        if self.enemy_list[i] then
            self:drawEnemy(self.all_enemies[i], 0, (i - page_offset - 1) * self.separation)
        end
    end
end

function BattleEnemySelect:drawEnemy(enemy, x, y)
    self:drawName(enemy, x, y)
    self:drawIcons(enemy, x, y)
    self:drawComment(enemy, x, y)
    -- drawXACT
    self:drawGauges(enemy, x, y)
end

function BattleEnemySelect:drawName(enemy, x, y)
    local name_colors = enemy:getNameColors()
    if type(name_colors) ~= "table" then
        name_colors = {name_colors}
    end

    if #name_colors <= 1 then
        self:drawSingleColorName(enemy, x, y)
    else
        self:drawGradientName(enemy, x, y)
    end
end

function BattleEnemySelect:drawSingleColorName(enemy, x, y)
    local name_colors = enemy:getNameColors()
    if type(name_colors) ~= "table" then
        name_colors = {name_colors}
    end

    -- should this be in drawname? also, see if dr greys out names that aren't white
    local default_color = (self:canSelectEnemy(enemy) and PALETTE["battle_text"]) or PALETTE["battle_text_unusable"]

    Draw.setFont(self.font)
    Draw.setColor(name_colors[1] or PALETTE["battle_text"])
    Draw.print(enemy.name, x, y)
end

function BattleEnemySelect:drawGradientName(enemy, x, y)
    local name_colors = enemy:getNameColors()
    if type(name_colors) ~= "table" then
        name_colors = {name_colors}
    end

    Draw.setFont(self.font)
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
    Draw.pushShader(shader, {colors = color_canvas, colorSize = {#name_colors, 1}})
        Draw.drawCanvas(canvas, x, y)
    Draw.popShader()
end

function BattleEnemySelect:drawComment(enemy, x, y)
    local text_width = self.font:getWidth(enemy.name)
    Draw.setColor(PALETTE["battle_enemy_comment"])

    if (x + ((text_width + 60) + (self.font:getWidth(enemy.comment) / 2))) < 415 then
        Draw.print(enemy.comment, x + (text_width + 60), y)
    else
        Draw.print(enemy.comment, x + (text_width + 60), y, 0, 0.5, 1)
    end
end

function BattleEnemySelect:drawIcons(enemy, x, y)
    -- ehhhhhh
    local spare_icon, tired_icon = self:drawDefaultIcons(enemy, x, y)
    self:drawCustomIcons(enemy, x, y, spare_icon, tired_icon)
end

-- redo icons
function BattleEnemySelect:drawDefaultIcons(enemy, x, y)
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

function BattleEnemySelect:drawCustomIcons(enemy, x, y, spare_icon, tired_mark)
    local text_width = self.font:getWidth(enemy.name)

    Draw.resetColor()

    -- doesn't this not work? also do it better
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

function BattleEnemySelect:drawGauges(enemy, x, y)
    self:drawHPGauge(enemy, x, y)
    self:drawMercyGauge(enemy, x, y)
end

function BattleEnemySelect:drawHPGauge(enemy, x, y)
    --if self.battle.state_reason ~= "XACT" then -- detect this better
        local hp_x = (self.draw_mercy and x + 340 or x + 430)
        local percent = enemy.health / enemy.max_health

        if enemy.selectable then
            Draw.setColor(PALETTE["action_health_bg"])
            Draw.rectangle("fill", hp_x, y + 5, 81, 16)

            Draw.setColor(PALETTE["action_health"])
            Draw.rectangle("fill", hp_x, y + 5, math.ceil(percent * 81), 16)

            if self.draw_percents then
                Draw.setColor(PALETTE["action_health_text"])
                Draw.print(math.ceil(percent * 100) .. "%", hp_x + 4, y + 5, 0, 1, 0.5)
            end
        end
   -- end
end

function BattleEnemySelect:drawMercyGauge(enemy, x, y)
    if self.draw_mercy then
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

            if self.draw_percents and self:canSelectEnemy(enemy) then
                Draw.setColor(PALETTE["battle_mercy_text"])
                Draw.print(math.ceil(enemy.mercy) .. "%", gauge_x + 4, y + 5, 0, 1, 0.5)
            end
        end
    end
end

function BattleEnemySelect:drawArrows()
    -- maybe space these out more depending on items_per_page?
    local page = self:getCurrentPage()
    local max_pages = self:getCurrentMaxPages()

    local arrow_texture = self:getTexture("arrow")
    local offset = math.sin(Kristal.getTime() * 6) * 2

    Draw.resetColor()
    if page > 0 then
        Draw.draw(arrow_texture, -60, 20 - offset, 0, 1, -1)
    end
    if page < max_pages then
        Draw.draw(arrow_texture, -60, 70 + offset)
    end
    -- test this
end

function BattleEnemySelect:draw()
    self:drawMenu()
    -- different function so hooks (for some reason if you use them) don't have to do a super call
    super.draw(self)
end

-- Input

function BattleEnemySelect:handleMenuInput(key)
    local enemies = self.all_enemies
    local enemy_count = #self.all_enemies

    if Input.isConfirm(key) then
        Input.clear(key, true)
        self:select()
        return
    end
    if Input.isCancel(key) then
        self:cancel()
        return
    end
    if Input.is("up", key) then
        if enemy_count == 0 then return end
        local old_position = self.current_enemy
        local give_up = 0
        repeat
            give_up = give_up + 1
            if give_up >= 100 then return end
            self.current_enemy = Utils.clampWrap(self.current_enemy - 1, 1, enemy_count)
        until(enemies[self.current_enemy] and self:canSelectCurrentEnemy()) -- do this better

        if self.current_enemy ~= old_position then
            self.battle:stopAndPlaySound("ui_move")
        end
    end
    if Input.is("down", key) then
        if enemy_count == 0 then return end
        local old_position = self.current_enemy
        local give_up = 0
        repeat
            give_up = give_up + 1
            if give_up == 100 then return end
            self.current_enemy = Utils.clampWrap(self.current_enemy + 1, 1, enemy_count)
        until(enemies[self.current_enemy] and self:canSelectCurrentEnemy()) -- do this better

        if self.current_enemy ~= old_position then
            self.battle:stopAndPlaySound("ui_move")
        end
    end
end

function BattleEnemySelect:select()
    local battle = self.battle
    local enemies = self.all_enemies
    local current_enemy = self.current_enemy

    --event
--[[     if battle.encounter:onEnemySelect(battle.state_reason, current_enemy) then return end
    if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemySelect, battle.state_reason, current_enemy) then return end ]]
    battle:stopAndPlaySound("ui_select")
    if #self.enemies == 0 then return end

    battle:clearMenuItems()

    if battle.state_reason == "ATTACK" then
        battle:pushAction("ATTACK", enemies[current_enemy])
    elseif battle.state_reason == "ACT" then
        -- functionify
        local enemy = enemies[current_enemy]
        -- callbackify
        local battle = Game.battle
        for _,act in ipairs(enemy.acts) do
            local insert = not act.hidden
            if act.character and battle:getCurrentlySelectingMember().chara.id ~= act.character then
                insert = false
            end
            if act.party and (#act.party > 0) then
                for _,party_id in ipairs(act.party) do
                    if not battle:getPartyIndex(party_id) then
                        insert = false
                        break
                    end
                end
            end
            if insert then
                battle:addMenuItem({
                    ["name"] = act.name,
                    ["tp"] = act.tp,
                    ["description"] = act.description,
                    ["party"] = act.party,
                    ["color"] = act.color,
                    ["highlight"] = act.highlight or enemy,
                    ["icons"] = act.icons,
                    ["callback"] = function(menu_item)
                        battle:pushAction("ACT", enemy, menu_item)
                    end
                })
            end
        end
        if #battle:getMenuItems() > 0 then
            battle:setState("MENUSELECT", "ACT", {enemy = enemy})
        end
    elseif battle.state_reason == "SPARE" then
        battle:pushAction("SPARE", enemies[current_enemy])
    elseif battle.state_reason == "SPELL" then
        battle:pushAction("SPELL", enemies[current_enemy], battle.state_vars["selected_spell"])
    elseif battle.state_reason == "ITEM" then
        battle:pushAction("ITEM", enemies[current_enemy], battle.state_vars["selected_item"])
    else
        battle:nextParty()
    end
end

function BattleEnemySelect:cancel()
    local battle = self.battle
    local current_enemy = self.current_enemy
--[[     if battle.encounter:onEnemyCancel(battle.state_reason, current_enemy) then return end
    if Kristal.callEvent(KRISTAL_EVENT.onBattleEnemyCancel, battle.state_reason, current_enemy) then return end ]]
    battle:stopAndPlaySound("ui_select")

    if battle.state_reason == "SPELL" then
        battle:setState("MENUSELECT", "SPELL")
    elseif battle.state_reason == "ITEM" then
        battle:setState("MENUSELECT", "ITEM")
    else
        battle:setState("ACTIONSELECT", "CANCEL")
    end
end

function BattleEnemySelect:onKeyPressed(key)
    self:handleMenuInput(key)
end

function BattleEnemySelect:canDeepCopy()
    return false
end

return BattleEnemySelect