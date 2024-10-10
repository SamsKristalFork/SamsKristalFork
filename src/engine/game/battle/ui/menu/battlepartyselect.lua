local BattlePartySelect, super = Class(Object)

function BattlePartySelect:init(ui, x, y)
    super.init(self, x or 80, y or 50)

    self.ui = ui
    self.battle = ui.battle

    self.current_member = 1

    self.separation = 30
    self.items_per_page = 3

    self.party = self.battle.party

    self.textures = {
        ["heart"] = Assets.getTexture("player/heart"),
        ["arrow"] = Assets.getTexture("ui/page_arrow_down")
    }

    self.font = Assets.getFont("main")
end

-- Getters

function BattlePartySelect:getTexture(texture)
    if self.textures[texture] then
        return self.textures[texture]
    end
end

function BattlePartySelect:getCurrentMember()
    return self.party[self.current_member]
end

function BattlePartySelect:getCurrentPage()
    return math.ceil(self.current_member / self.items_per_page) - 1
end

function BattlePartySelect:getCurrentMaxPages()
    return math.ceil(#self.party / self.items_per_page) - 1
end

function BattlePartySelect:getCurrentPageOffset()
    return self:getCurrentPage() * self.items_per_page
end

-- Functions

function BattlePartySelect:resetPosition()
    self.current_member = 1
end

function BattlePartySelect:isHighlighted(battler)
    return self:getCurrentMember() == battler
end

-- Draw
-- menu item system for callbacks?

function BattlePartySelect:drawMenu()
    self:drawCursor()
    self:drawMembers()
    self:drawArrows()
end

function BattlePartySelect:drawCursor()
    local page_offset = self:getCurrentPageOffset()
    Draw.setColor(self.battle.encounter:getSoulColor())
    Draw.draw(self:getTexture("heart"), -25, -20 + ((self.current_member - page_offset) * self.separation))
end

function BattlePartySelect:drawMembers()
    local page_offset = self:getCurrentPageOffset()

    for i = page_offset + 1, math.min(page_offset + self.items_per_page, #self.party) do
        self:drawMember(self.party[i], 0, (i - page_offset - 1) * self.separation)
    end
end

function BattlePartySelect:drawMember(member, x, y)
    self:drawName(member, x, y)
    self:drawGauges(member, x, y)
end

function BattlePartySelect:drawName(member, x, y)
    Draw.setFont(self.font)
    Draw.setColor(PALETTE["battle_text"])
    Draw.print(member.chara:getName(), x, y)
end

function BattlePartySelect:drawGauges(member, x, y)
    self:drawHPGauge(member, x, y)
end

function BattlePartySelect:drawHPGauge(member, x, y)
    local chara = member.chara

    local gauge_x = x + 320
    local gauge_y = y + 5

    -- gauge width/height options?
    Draw.setColor(PALETTE["action_health_bg"]) -- i hate this naming
    Draw.rectangle("fill", gauge_x, gauge_y, 101, 16)

    local percent = chara:getHealth() / chara:getStat("health")
    Draw.setColor(PALETTE["action_health"])
    Draw.rectangle("fill", gauge_x, gauge_y, math.ceil(percent * 101), 16)
end

function BattlePartySelect:drawArrows()
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
end

function BattlePartySelect:draw()
    self:drawMenu()
    super.draw(self)
end

-- Input

function BattlePartySelect:handleInput(key)
    -- envent
    if Input.isConfirm(key) then
        local result = self:select()
        if result then return end
    end
    if Input.isCancel(key) then
        self:cancel()
        return
    end
    if Input.is("up", key) then
        -- does it not play a sound if it doesn't move in dr?
        self.current_member = Utils.clampWrap(self.current_member - 1, 1, #self.party)
        self.battle:stopAndPlaySound("ui_move")
    elseif Input.is("down", key) then
        self.current_member = Utils.clampWrap(self.current_member + 1, 1, #self.party)
        self.battle:stopAndPlaySound("ui_move")
    end
end

function BattlePartySelect:select()
    self.battle:stopAndPlaySound("ui_select")
    if self.battle.state_reason == "SPELL" then
        self.battle:pushAction("SPELL", self.party[self.current_member], self.battle.state_vars["selected_spell"])
    elseif self.battle.state_reason == "ITEM" then
        self.battle:pushAction("ITEM", self.party[self.current_member], self.battle.state_vars["selected_item"])
    else
        self.battle:nextParty()
    end
    return true
end

function BattlePartySelect:cancel()
    local battle = self.battle

    self.battle:stopAndPlaySound("ui_move")
    if battle.state_reason == "SPELL" then
        battle:setState("MENUSELECT", "SPELL")
    elseif battle.state_reason == "ITEM" then
        battle:setState("MENUSELECT", "ITEM")
    else
        battle:setState("ACTIONSELECT", "CANCEL")
    end
end

function BattlePartySelect:onKeyPressed(key)
    self:handleInput(key)
end

function BattlePartySelect:canDeepCopy()
    return false
end

return BattlePartySelect