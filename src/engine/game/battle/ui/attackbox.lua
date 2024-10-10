local AttackBox, super = Class(Object)

function AttackBox:init(battler, index, bolt_offset, x, y)
    super.init(self, x, y)

    self.battler = battler
    self.index = index
    self.bolt_offset = bolt_offset

    self.bolt_count = 1
    self.bolt_speed = 8
    self.bolt_target = 80 + 2

    self.bolt_start_x = self.bolt_target + (self.bolt_offset * self.bolt_speed)

    self:createHeadSprite()
    self:createPressSprite()

    self:createBolts()

    self.fade = 0

    self.done = false
    self.fading = false
end

function AttackBox:createHeadSprite()
    self.head_sprite = Sprite(self.battler.chara:getHeadIcons().."/head", 21, 19)
    self.head_sprite:setOrigin(0.5)
    self:addChild(self.head_sprite)
end

function AttackBox:createPressSprite()
    -- just in case i remake the worst mechanic idea ever
    self.press_sprite = Sprite("ui/battle/press", 42, 0)
    self:addChild(self.press_sprite)
end

function AttackBox:createBolts()
    self.bolts = {}
    for i = 1, self.bolt_count do
        local bolt = AttackBolt(self, self.bolt_start_x)
        bolt.layer = 1
        self:addChild(bolt)
        table.insert(self.bolts, bolt)
    end
end

function AttackBox:getClose()
    local bolt = self.bolts[1]
    if bolt then
        return math.floor((bolt.x - (self.bolt_target - 2)) / self.bolt_speed)
    end
end

function AttackBox:finishAttack()
    self.done = true
end

function AttackBox:fadeOut()
    self.fading = true
end

function AttackBox:update()
    self:updateBolts()
    self:updateFade()

    super.update(self)
end

function AttackBox:updateBolts()
    if not self.done then
        for _,bolt in ipairs(self.bolts) do
            -- this is why timing appears inconsistent with dr
            bolt.x = (self.bolt_offset * self.bolt_speed) - (bolt.timer * self.bolt_speed)
        end
    end
end

function AttackBox:updateFade()
    if self.fading then
        self.fade = Utils.approach(self.fade, 1, 0.08 * DTMULT) -- what is this jank
    end
end

function AttackBox:draw()
    self:drawBox()
    self:drawTarget()

    super.draw(self)

    self:drawFade()
end

function AttackBox:drawBox()
    local color = {self.battler.chara:getAttackBoxColor()}

    Draw.setLineWidth(2)
    Draw.setLineStyle("rough")

    local ch1_offset = Game:getConfig("oldUIPositions")

    Draw.setColor(color)
    Draw.rectangle("line", 80, ch1_offset and 0 or 1, (15 * self.bolt_speed) + 3, ch1_offset and 37 or 36)
end

function AttackBox:drawTarget()
    local color = {self.battler.chara:getAttackTargetColor()}

    Draw.setLineWidth(2)
    Draw.setLineStyle("rough")

    Draw.setColor(color)
    Draw.rectangle("line", 83, 1, 8, 36)
    Draw.setColor(COLORS.black)
    Draw.rectangle("fill", 84, 2, 6, 34)
end

function AttackBox:drawFade()
    Draw.setColor(COLORS.black[1], COLORS.black[2], COLORS.black[3], self.fade)
    Draw.rectangle("fill", 0, 0, SCREEN_WIDTH, 300)
end

function AttackBox:hit()
    local bolt = self.bolts[1]
    local frame = math.abs(self:getClose())

    local points
    if frame == 0 then
        bolt:burst({COLORS.yellow}, 0.2)
        points = 150
    elseif frame == 1 then
        bolt:burst()
        points = 120
    elseif frame == 2 then
        bolt:burst()
        points = 110
    else
        bolt:burst({self.battler.chara:getEnemyDamageColor()})
        points = 100 - (frame * 2)

        -- deltarune has an extra one of these if the frame >= 15 that
        -- applies the color and doesn't give points, but the game won't you attack
        -- until frame < 15... 
    end

    table.remove(self.bolts, 1)

    if #self.bolts == 0 then
        self:finishAttack()
    end

    return points
end

function AttackBox:miss()
    local bolt = self.bolts[1]
    bolt:remove()
    table.remove(self.bolts, 1)

    if #self.bolts == 0 then
        self:finishAttack()
    end
end

return AttackBox