local AttackBolt, super = Class(Object)

-- create afterimages here

function AttackBolt:init(attack_box, x, y, width, height)
    super.init(self, x, y, width or 6, height or 38)

    self.attack_box = attack_box

    self.timer = 0
    self.afterimage_timer = 0
    self.afterimage_count = 0

    self.bursting = false
    self.burst_speed = 0.1
    self.burst_color = COLORS.white
end

function AttackBolt:burst(color, speed)
    if color then self:setColor(color[1], color[2], color[3]) end
    if speed then self.burst_speed = speed end

    if self.parent.parent then
        self.layer = 5
        self:setPosition(self:getRelativePosFor(self.parent.parent))
        self:setParent(self.parent.parent)    
    end

    self.bursting = true

    self:fadeOutSpeedAndRemove(0.1)
end

function AttackBolt:update()
    self.timer = self.timer + DTMULT
    self:updateAfterImages()
    self:updateBurst()

    super.update(self)
end

function AttackBolt:updateAfterImages()
    if not self.bursting then
        self.afterimage_timer = self.afterimage_timer + DTMULT / 2
        while math.floor(self.afterimage_timer) > self.afterimage_count do
            self.afterimage_count = self.afterimage_count + 1
            local afterimage = Rectangle(self.x, 0, self.width, self.height)
            afterimage.layer = 3
            afterimage.alpha = 0.4
            afterimage:fadeOutSpeedAndRemove()
            self.parent:addChild(afterimage)
        end
    end
end

function AttackBolt:updateBurst()
    if self.bursting then
        self.scale_x = self.scale_x + (self.burst_speed * DTMULT)
        self.scale_y = self.scale_y + (self.burst_speed * DTMULT)

        self.x = self.x + ((1 - self.width) * 0.1 / 2.7) * DTMULT
        self.y = self.y + ((1 - self.height) * 0.1 / 2.5) * DTMULT
    end
end

function AttackBolt:drawBolt()
    Draw.rectangle("fill", 0, 0, self.width, self.height)
end

function AttackBolt:draw()
    self:drawBolt()

    super.draw(self)
end

return AttackBolt