---@class OverworldStatus : Object
---@overload fun(...) : OverworldStatus
local OverworldStatus, super = Class(Object)

function OverworldStatus:init()
    super.init(self, 0, -80)

    self.parallax_x = 0
    self.parallax_y = 0

    self.animation_done = false
    self.animation_timer = 0
    self.animate_out = false
    self.animation_y = -63

    self.action_boxes = {}

    for index, chara in ipairs(Game.party) do
        local x_pos = (index - 1) * 213

        if #Game.party == 2 then
            if Game:getConfig("oldUIPositions") then
                if index == 1 then
                    x_pos = 105
                else
                    x_pos = 325
                end
            else
                if index == 1 then
                    x_pos = 108
                else
                    x_pos = 322
                end
            end
        elseif #Game.party == 1 then
            x_pos = 213
        end

        local action_box = OverworldActionBox(x_pos, 0, index, chara)
        self:addChild(action_box)
        table.insert(self.action_boxes, action_box)
        chara:onCreateWorldActionBox(action_box)
    end

    self.auto_hide_timer = 0
end

function OverworldStatus:transitionIn()
    if self.animate_out then
        self.animate_out = false
        self.animation_timer = 0
        self.animation_done = false
    end
end

function OverworldStatus:transitionOut()
    if not self.animate_out then
        self.animate_out = true
        self.animation_timer = 0
        self.animation_done = false
    end
end

function OverworldStatus:update()
    self.animation_timer = self.animation_timer + DTMULT
    self.auto_hide_timer = self.auto_hide_timer + DTMULT
    if Game.world.menu or Game.world:inBattle() then
        -- If we're in an overworld battle, or the menu is open, we don't want the health bar to disappear
        self.auto_hide_timer = 0
    end

    if self.auto_hide_timer > 60 then -- After two seconds outside of a battle, we hide the health bar
        self:transitionOut()
    end

    local max_time = self.animate_out and 3 or 8

    if self.animation_timer > max_time + 1 then
        self.animation_done = true
        self.animation_timer = max_time + 1
        if self.animate_out then
            Game.world.status = nil
            self:remove()
            return
        end
    end

    if not self.animate_out then
        if self.animation_y < 0 then
            if self.animation_y > -40 then
                self.animation_y = self.animation_y + math.ceil(-self.animation_y / 2.5) * DTMULT
            else
                self.animation_y = self.animation_y + 30 * DTMULT
            end
        else
            self.animation_y = 0
        end
    else
        if self.animation_y > -63 then
            if self.animation_y > 0 then
                self.animation_y = self.animation_y - math.floor(self.animation_y / 2.5) * DTMULT
            else
                self.animation_y = self.animation_y - 30 * DTMULT
            end
        else
            self.animation_y = -63
        end
    end

    self.y = 480 - (self.animation_y + 63)

    super.update(self)
end

function OverworldStatus:draw()
    -- Draw the black background
    Draw.setColor(PALETTE["world_fill"])
    love.graphics.rectangle("fill", 0, 2, 640, 61)

    super.draw(self)
end

function OverworldStatus:react(chara, reaction)
    local index = Game:getPartyIndex(chara)
    if index and self.action_boxes[index] then
        self.action_boxes[index]:react(reaction)
    end
end

return OverworldStatus