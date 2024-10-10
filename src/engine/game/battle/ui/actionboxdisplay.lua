---@class ActionBoxDisplay : Object
---@overload fun(...) : ActionBoxDisplay
local ActionBoxDisplay, super = Class(Object)

function ActionBoxDisplay:init(action_box, x, y)
    super.init(self, x, y)

    self.action_box = action_box
    self.battler = self.action_box.battler
    self.index = self.action_box.index
    -- data offset ref if i keep it

    self.battle = self.action_box.battle
    self.battle_ui = self.action_box.battle_ui

    self.gauge_width = 76

    self.hp_font = Assets.getFont("smallnumbers")
end

function ActionBoxDisplay:draw()
    self:drawDisplay()
    super.draw(self)
end

function ActionBoxDisplay:drawDisplay()
    self:drawFill()
    self:drawBorders()
    self:drawHP()
end

function ActionBoxDisplay:drawFill()
    Draw.setColor(PALETTE["action_fill"])
    Draw.rectangle("fill", 2, Game:getConfig("oldUIPositions") and 3 or 2, 209, Game:getConfig("oldUIPositions") and 34 or 35)
end

function ActionBoxDisplay:drawBorders()
    if self.battle.current_selecting_index == self.index then
        Draw.setColor(self.battler.chara:getColor())
    else
        Draw.setColor(PALETTE["action_strip"], 1)
    end

    Draw.setLineWidth(2)
    Draw.line(0  , Game:getConfig("oldUIPositions") and 2 or 1, 213, Game:getConfig("oldUIPositions") and 2 or 1)

    Draw.setLineWidth(2)
    if self.battle.current_selecting_index == self.index then
        Draw.line(1  , 2, 1,   36)
        Draw.line(212, 2, 212, 36)
    end
end

function ActionBoxDisplay:drawHP()
    self:drawHPNumbers()
    self:drawHPBar()
end

function ActionBoxDisplay:drawHPNumbers()
    local health = self.battler.chara:getHealth()
    local max_health = self.battler.chara:getStat("health")

    local color = PALETTE["action_health_text"]
    if health <= 0 then
        color = PALETTE["action_health_text_down"]
    elseif health <= max_health / 4 then
        color = PALETTE["action_health_text_low"]
    else
        color = PALETTE["action_health_text"]
    end

    local health_offset = 0
    health_offset = (#tostring(health) - 1) * 8

    Draw.setColor(color)
    Draw.setFont(self.hp_font)
    Draw.print(health, 152 - health_offset, 9 - self.action_box.display_offset)
    Draw.setColor(PALETTE["action_health_text"])
    Draw.print("/", 161, 9 - self.action_box.display_offset)
    local string_width = self.hp_font:getWidth(tostring(max_health))
    Draw.setColor(color)
    Draw.print(max_health, 205 - string_width, 9 - self.action_box.display_offset)
end

function ActionBoxDisplay:drawHPBar()
    Draw.setColor(PALETTE["action_health_bg"])
    Draw.rectangle("fill", 128, 22 - self.action_box.display_offset, 76, 9)

    local health_percent = (self.battler.chara:getHealth() / self.battler.chara:getStat("health")) * 76

    if health_percent > 0 then
        Draw.setColor(self.battler.chara:getColor())
        Draw.rectangle("fill", 128, 22 - self.action_box.display_offset, math.ceil(health_percent), 9)
    end
end

return ActionBoxDisplay