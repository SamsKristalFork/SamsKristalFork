local BattleUI, super = Class(Object)

function BattleUI:init(battle, x, y)
    super.init(self, x, y)
    
    self.battle = battle

    self.parallax_x = 0
    self.parallax_y = 0

    self:createEncounterText()
    self:createChoicebox()
    self:createShortActText()
    self:createActionBoxes()
    self:createMenus()
    self:clearAttackBoxes()

    self.shown = false

    self.shown_y = self.y - 157

    -- IN, OUT
    self.transition_state = nil

    self.transition_timer = 0
end

function BattleUI:getMenu(menu)
    for id, imenu in pairs(self.menus) do
        if menu == id then
            return imenu.object
        end
    end
end

function BattleUI:createEncounterText()
    self.encounter_text = Textbox(30, 53, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53, "main_mono", nil, true)
    self.encounter_text.text.line_offset = 0
    self.encounter_text:setText("")
    self.encounter_text.debug_rect = {-30, -12, SCREEN_WIDTH+1, 124}
    self:addChild(self.encounter_text)
end

function BattleUI:createChoicebox()
    self.choice_box = Choicebox(56, 49, 529, 103, true)
    self.choice_box.active = false
    self.choice_box.visible = false
    self:addChild(self.choice_box)
end

function BattleUI:createShortActText()
    self.short_act_text = {}
    local offset = 0
    for i = 1, 3 do
        local text = DialogueText("", 30, 51 + offset, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53, {wrap = false, line_offset = 0})
        table.insert(self.short_act_text, text)
        self:addChild(text)

        offset = offset + 30
    end
end

function BattleUI:createMenus()
    -- before and oncreatebattlemenus event
    self.menus = {
        ["menu_select"]  = {object = BattleMenuSelect(self,  30, 50), states = "MENUSELECT"},
        ["enemy_select"] = {object = BattleEnemySelect(self, 80, 50), states = "ENEMYSELECT"},
        ["party_select"] = {object = BattlePartySelect(self, 80, 50), states = "PARTYSELECT"}
    }
    -- before and oncreatebattlemenus event

    for _,menu in pairs(self.menus) do
        self:addChild(menu.object)
    end
end

function BattleUI:createActionBoxes()
    self.action_boxes = {}

    local offset = 0
    local gap = 0

    if #Game.battle.party == 3 then
        offset = 0
        gap = 0
    elseif #Game.battle.party == 2 then
        offset = 108
        gap = 1
        if Game:getConfig("oldUIPositions") then
            offset = 106
            gap = 7
        end
    elseif #Game.battle.party == 1 then
        offset = 213
        gap = 0
    end

    for index, battler in ipairs(Game.battle.party) do
        local action_box = ActionBox(offset + (index - 1) * (213 + gap), 0, index, battler)
        self:addChild(action_box)
        table.insert(self.action_boxes, action_box)
        -- better callback name, move to actionbox
        battler.chara:onCreateBattleActionBox(action_box)
    end
end

function BattleUI:clearAttackBoxes()
    if self.attack_boxes then
        for _,attack_box in ipairs(self.attack_boxes) do
            attack_box:remove()
        end
    end
    self.attack_boxes = {}
end

function BattleUI:createAttackBoxes(attack_order)
    local last_offset = -1
    local offset = 0
    for i = 1, #attack_order do
        offset = offset + last_offset

        local battler = attack_order[i]
        local index = self.battle:getPartyIndex(battler.chara.id)
        local attack_box = AttackBox(battler, index, 30 + offset, 0, 40 + (38 * (index - 1)))
        attack_box.layer = -10 + (index * 0.01)
        self:addChild(attack_box)
        table.insert(self.attack_boxes, attack_box)

        if i < #attack_order and last_offset ~= 0 then
            last_offset = Utils.pick{0, 10, 15}
        else
            last_offset = Utils.pick{10, 15}
        end
    end
end

function BattleUI:startAttack(attackers)
    local attack_order = Utils.pickMultiple(attackers, #attackers)
    self:clearAttackBoxes()
    self:createAttackBoxes(attack_order)
    self.attacking = true
end

function BattleUI:finishAttack()
    -- extra check here?
    for _,box in ipairs(self.attack_boxes) do
        box:fadeOut()
    end
end

function BattleUI:setEncounterText(text, after)
    self.encounter_text:setText(text, after)
end

function BattleUI:clearEncounterText()
    self.encounter_text:setActor(nil)
    self.encounter_text:setFace(nil)
    self.encounter_text:setFont()
    self.encounter_text:setAlign("left")
    self.encounter_text:setSkippable(true)
    self.encounter_text:setAdvance(true)
    self.encounter_text:setAuto(false)
    self.encounter_text:setText("")
end

function BattleUI:getCurrentActionBox()
    return self.action_boxes[self.battle.current_selecting_index]
end

function BattleUI:resetActionBoxes()
    for _,action_box in ipairs(self.action_boxes) do
        action_box:reset()
    end
end

function BattleUI:resetMenuCursorPositions()
    for id, menu in pairs(self.menus) do
        if menu.object.resetPosition then
            menu.object:resetPosition()
        end
    end
end

function BattleUI:isInActionSelect()
    return self.battle.state == "ACTIONSELECT"
end 

function BattleUI:isInMenu()
    local menu_states = {}
    for _,menu in pairs(self.menus) do
        if type(menu.states) == "string" then
            table.insert(menu_states, menu.states)
        elseif type(menu.states) == "table" then
            for _,state in ipairs(menu.states) do
                table.insert(menu_states, state)
            end
        end
    end
    return Utils.containsValue(menu_states, self.battle.state)
end

function BattleUI:getCurrentMenu()
    for _,menu in pairs(self.menus) do
        if type(menu.states) == "string" then
            menu.states = {menu.states}
        end

        if Utils.containsValue(menu.states, self.battle.state) then
            return menu
        end
    end
end

function BattleUI:isHighlighted(battler)
    -- event, then let the current menu determine it

    if self:isInMenu() then
        return self:getCurrentMenu().object:isHighlighted(battler)
    else
        return false
    end
end

function BattleUI:isShown()
    return self.shown
end

function BattleUI:show()
    if not self.shown then
        self:transitionIn()
        self.shown = true
    end
end

function BattleUI:hide()
    if self.shown then
        self:transitionOut()
        self.shown = false
    end
end

function BattleUI:transitionIn()
    self.y = self.init_y
    self.transition_state = "IN"
end

function BattleUI:transitionOut()
    self.y = self.shown_y
    self.transition_state = "OUT"
end

function BattleUI:updateTransition()
    if self.transition_state == "IN" then
        self:updateTransitionIn()
    elseif self.transition_state == "OUT" then
        self:updateTransitionOut()
    end
end

function BattleUI:updateTransitionIn()
    self.transition_timer = self.transition_timer + DTMULT
    
    if self.transition_timer > 12 then
        self.transition_state = nil
        self.transition_timer = 0
    end
    
    if self.y > self.shown_y then
        if self.shown_y - self.y < 40 then
            self.y = self.y + (math.ceil((self.shown_y - self.y) / 2.5) * DTMULT)
        else
            self.y = self.y + (30 * DTMULT)
        end
    else
        self.y = self.shown_y
    end
end

function BattleUI:updateTransitionOut()
    self.transition_timer = self.transition_timer + DTMULT

    if self.transition_timer > 6 then
        self.transition_state = nil
        self.transition_timer = 0
    end

    if self.y < self.init_y then
        if math.floor((self.init_y - self.y) / 5) > 15 then
            self.y = self.y + (math.floor((self.init_y - self.y) / 2.5) * DTMULT)
        else
            self.y = self.y + (30 * DTMULT)
        end
    else
        self.y = self.init_y
    end
end

function BattleUI:updateMenuVisibility()
    for _,menu in pairs(self.menus) do
        if type(menu.states) == "string" then
            menu.states = {menu.states}
        end

        menu.object.visible = Utils.containsValue(menu.states, self.battle.state)
    end
end

function BattleUI:update()
    self:updateTransition()
    self:updateMenuVisibility()
    self:updateAttacking()

    super.update(self)
end

function BattleUI:updateAttacking()
    if self.battle.state == "ATTACKING" then
        if self.attacking then
            local all_done = true
            for _,attack_box in ipairs(self.attack_boxes) do
                if not attack_box.done then
                    local frame = attack_box:getClose()
                    if frame <= -5 then
                        attack_box:miss()
    
                        local action = self.battle:getActionBy(attack_box.battler, true)
                        action.points = 0
    
                        if self.battle:processAction(action) then
                            self.battle:finishAction(action)
                        end
                    else
                        all_done = false
                    end
                end
            end
    
            if all_done then
                self.attacking = false
            end
        else
            if self.battle:areAllCurrentActionsDone() then
                self.battle:setState("ACTIONSDONE")
            end
        end
    end
end

function BattleUI:drawActionArea()
    -- Draw the top line of the action area
    Draw.setColor(PALETTE["action_strip"])
    Draw.rectangle("fill", 0, 37, 640, 3)
    -- Draw the background of the action area
    Draw.setColor(PALETTE["action_fill"])
    Draw.rectangle("fill", 0, 40, 640, 115)
end

function BattleUI:drawActionStrip()
    -- Draw the top line of the action strip
    Draw.setColor(PALETTE["action_strip"])
    Draw.rectangle("fill", 0, Game:getConfig("oldUIPositions") and 1 or 0, 640, Game:getConfig("oldUIPositions") and 3 or 2)
    -- Draw the background of the action strip
    Draw.setColor(PALETTE["action_fill"])
    Draw.rectangle("fill", 0, Game:getConfig("oldUIPositions") and 4 or 2, 640, Game:getConfig("oldUIPositions") and 33 or 35)
end

function BattleUI:draw()
    self:drawActionArea()
    self:drawActionStrip()
    super.draw(self)
end

function BattleUI:onKeyPressed(key)
    if self.battle:isInActionSelect() then
        self:handleActionButtonInput(key)
    elseif self.battle:isInMenu() then
        self:handleMenuInput(key)
    elseif self.battle.state == "ATTACKING" and self.attacking then
        self:handleAttackingInput(key)
    end
end

-- make this work with my expanding/collapsing buttons idea somehow, probably move these
-- to actionbox
function BattleUI:handleActionButtonInput(key)
    if self.battle.state == "ACTIONSELECT" then
        local action_box = self:getCurrentActionBox()
        --functionify, once more
        if action_box then
            if Input.isConfirm(key) then
                action_box:selectButton()
                Input.clear(key)
            elseif Input.isCancel(key) then
                local old_selecting_index = self.battle.current_selecting_index

                self.battle:previousParty()
    
                -- Only unselect this box if this is not the only active battler
                if self.battle.current_selecting_index ~= old_selecting_index then
                    action_box:unselectButton()
                end
            elseif Input.is("right", key) then
                action_box:nextButton()
            elseif Input.is("left", key) then
                action_box:previousButton()
            end
        end
    end
end

function BattleUI:handleMenuInput(key)
    -- event bullshit?
    self:getCurrentMenu().object:onKeyPressed(key)
end

function BattleUI:handleAttackingInput(key)
    if Input.isConfirm(key) then
        if self.attacking and not self.cancel_attack then
            local closest_frame, closest_attack_boxes = self:getClosestBolts()

            if closest_frame and (closest_frame < 15 and closest_frame > -5) then
                for _,attack_box in ipairs(closest_attack_boxes) do
                    local points = attack_box:hit()

                    local action = self.battle:getActionBy(attack_box.battler, true)
                    action.points = points
            
                    -- move to tryandprocessaction?
                    if self.battle:processAction(action) then
                        self.battle:finishAction(action)
                    end
                end
            end
        end
    end
end

function BattleUI:getClosestBolts()
    local closest_frame, closest_attack_boxes = nil, {}

    for _,attack_box in ipairs(self.attack_boxes) do
        if not attack_box.done then
            local frame = attack_box:getClose()
            if not closest_frame then
                closest_frame = frame
                table.insert(closest_attack_boxes, attack_box)
            elseif frame == closest_frame then
                table.insert(closest_attack_boxes, attack_box)
            elseif frame < closest_frame then
                closest_frame = frame
                closest_attack_boxes = {attack_box}
            end
        end
    end

    return closest_frame, closest_attack_boxes
end

function BattleUI:canDeepCopy()
    return false
end

return BattleUI