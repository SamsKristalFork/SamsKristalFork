---@class TensionBar : Object
---@overload fun(...) : TensionBar
local TensionBar, super = Class(Object)

function TensionBar:init(x, y, dont_animate)
    if Game.world and (not x) then
        local x2 = Game.world.camera:getRect()
        x = x2 - 25
    end

    -- rename like all of these variables
    -- make all the 196s based on the height of the tensionbar

    super.init(self, x or -25, y or 40)

    self.layer = BATTLE_LAYERS["ui"] - 1

    if Game:getConfig("oldTensionBar") then
        self.tp_bar_fill = Assets.getTexture("ui/battle/tp_bar_fill_old")
        self.tp_bar_outline = Assets.getTexture("ui/battle/tp_bar_outline_old")
    else
        self.tp_bar_fill = Assets.getTexture("ui/battle/tp_bar_fill")
        self.tp_bar_outline = Assets.getTexture("ui/battle/tp_bar_outline")
    end

    self.width = self.tp_bar_outline:getWidth()
    self.height = self.tp_bar_outline:getHeight()

    self.apparent = 0
    self.current = 0
    self.font = Assets.getFont("main")
    self.tp_text = Assets.getTexture("ui/battle/tp_text")

    self.parallax_y = 0

    self.animating_in = (not dont_animate) or false

    self.animation_timer = 0

    self.preview_timer = 0

    self.tension_preview = 0
    self.shown = false
end

function TensionBar:show()
    if not self.shown then
        self:resetPhysics()
        self.x = self.init_x
        self.shown = true
        self.animating_in = true
        self.animation_timer = 0
    end
end

function TensionBar:hide()
    if self.shown then
        self.animating_in = false
        self.shown = false
        self.physics.speed_x = -10
        self.physics.friction = -0.4
    end
end

function TensionBar:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Tension: "  .. Utils.round(self:getPercentageFor(Game:getTension()) * 100) .. "%")
    table.insert(info, "Apparent: " .. Utils.round(self.apparent / 2.5))
    table.insert(info, "Current: "  .. Utils.round(self.current / 2.5))
    return info
end

function TensionBar:getTension250()
    return self:getPercentageFor(Game:getTension()) * 250
end

function TensionBar:setTensionPreview(amount)
    self.tension_preview = amount
end

function TensionBar:getPercentageFor(amount)
    return amount / Game:getMaxTension()
end

function TensionBar:getPercentageFor250(amount)
    return amount / 250
end

function TensionBar:getMultipliedPercentageFor250(amount)
    return (amount / 250) * Game:getMaxTension()
end

function TensionBar:updateSlideIn()
    if self.animating_in then
        self.animation_timer = self.animation_timer + DTMULT
        if self.animation_timer > 12 then
            self.animation_timer = 12
            self.animating_in = false
        end

        self.x = Ease.outCubic(self.animation_timer, self.init_x, 25 + 38, 12)
    end
end

function TensionBar:updateAmount()
    if (math.abs((self.apparent - self:getTension250())) < 20) then
        self.apparent = self:getTension250()
    elseif (self.apparent < self:getTension250()) then
        self.apparent = self.apparent + (self:getMultipliedPercentageFor250(20) * DTMULT)
    elseif (self.apparent > self:getTension250()) then
        self.apparent = self.apparent - (self:getMultipliedPercentageFor250(20) * DTMULT)
    end
    if (self.apparent ~= self.current) then
        local difference = (self.apparent - self.current)

        if difference > 0 then
            self.current = self.current + (self:getMultipliedPercentageFor250(2) * DTMULT)
        end
        if difference > self:getMultipliedPercentageFor250(10) then
            self.current = self.current + (self:getMultipliedPercentageFor250(2) * DTMULT)
        end
        if difference > self:getMultipliedPercentageFor250(25) then
            self.current = self.current + (self:getMultipliedPercentageFor250(3) * DTMULT)
        end
        if difference > self:getMultipliedPercentageFor250(50) then
            self.current = self.current + (self:getMultipliedPercentageFor250(4) * DTMULT)
        end
        if difference > self:getMultipliedPercentageFor250(100) then
            self.current = self.current + (self:getMultipliedPercentageFor250(5) * DTMULT)
        end
        if difference < 0 then
            self.current = self.current - (self:getMultipliedPercentageFor250(2) * DTMULT)
        end
        if difference < self:getMultipliedPercentageFor250(-10) then
            self.current = self.current - (self:getMultipliedPercentageFor250(2) * DTMULT)
        end
        if difference < self:getMultipliedPercentageFor250(-25) then
            self.current = self.current - (self:getMultipliedPercentageFor250(3) * DTMULT)
        end
        if difference < self:getMultipliedPercentageFor250(-50) then
            self.current = self.current - (self:getMultipliedPercentageFor250(4) * DTMULT)
        end
        if difference < self:getMultipliedPercentageFor250(-100) then
            self.current = self.current - (self:getMultipliedPercentageFor250(5) * DTMULT)
        end
        if (math.abs(difference) < 3) then
            self.current = self.apparent
        end
    end

    if (self.tension_preview > 0) then
        self.preview_timer = self.preview_timer + DTMULT
    end
end

function TensionBar:getCurrentValue()
    return math.floor(self:getMultipliedPercentageFor250(self.apparent))
end

function TensionBar:isMax()
    return self:getCurrentValue() > 100
end

function TensionBar:update()
    self:updateSlideIn()
    self:updateAmount()

    super.update(self)
end

function TensionBar:drawText()
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.tp_text, -30, 30)

    Draw.setFont(self.font)
    if not self:isMax() then
        --split
        Draw.print(tostring(math.floor(self:getMultipliedPercentageFor250(self.apparent))), -30, 70)
        Draw.print("%", -25, 95)
    else
        self:drawMaxText()
    end
end

function TensionBar:drawMaxText()
    Draw.setColor(PALETTE["tension_maxtext"])

    Draw.print("M", -28, 70)
    Draw.print("A", -24, 90)
    Draw.print("X", -20, 110)
end

function TensionBar:drawBack()
    Draw.setColor(PALETTE["tension_back"])
    Draw.pushScissor()
    Draw.scissorPoints(0, 0, 25, self.height - (self:getPercentageFor250(self.current) * self.height) + 1)
    Draw.draw(self.tp_bar_fill, 0, 0)
    Draw.popScissor()
end

function TensionBar:drawFill()
    if (self.apparent < self.current) then
        Draw.setColor(PALETTE["tension_decrease"])
        Draw.pushScissor()
        Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1, 25, self.height)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        Draw.setColor(PALETTE["tension_fill"])
        Draw.pushScissor()
        Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.apparent) * self.height) + 1 + (self:getPercentageFor(self.tension_preview) * self.height), 25, self.height)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent > self.current) then
        Draw.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.apparent) * self.height) + 1, 25, self.height)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        Draw.setColor(PALETTE["tension_fill"])
        if self:isMax() then
            Draw.setColor(PALETTE["tension_max"])
        end
        Draw.pushScissor()
        Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1 + (self:getPercentageFor(self.tension_preview) * self.height), 25, self.height)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    elseif (self.apparent == self.current) then
        Draw.setColor(PALETTE["tension_fill"])
        if self:isMax() then
            Draw.setColor(PALETTE["tension_max"])
        end
        Draw.pushScissor()
        Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1 + (self:getPercentageFor(self.tension_preview) * self.height), 25, self.height)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end

    if (self.tension_preview > 0) then
        local alpha = (math.abs((math.sin((self.preview_timer/ 8)) * 0.5)) + 0.2)
        local color_to_set = {1, 1, 1, alpha}

        local theight = self.height - (self:getPercentageFor250(self.current) * self.height)
        local theight2 = theight + (self:getPercentageFor(self.tension_preview) * self.height)
        -- Note: causes a visual bug.
        if (theight2 > ((0 + self.height) - 1)) then
            theight2 = ((0 + self.height) - 1)
            color_to_set = {COLORS.dkgray[1], COLORS.dkgray[2], COLORS.dkgray[3], 0.7}
        end

        Draw.pushScissor()
        Draw.scissorPoints(0, theight2 + 1, 25, theight + 1)

        -- No idea how Deltarune draws this, cause this code was added in Kristal:
        local r,g,b,_ = love.graphics.getColor()
        Draw.setColor(r, g, b, 0.7)
        Draw.draw(self.tp_bar_fill, 0, 0)
        -- And back to the translated code:
        Draw.setColor(color_to_set)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()

        Draw.setColor(1, 1, 1, 1)
    end

    if ((self.apparent > 20) and (self.apparent < 250)) then
        Draw.setColor(1, 1, 1, 1)
        Draw.pushScissor()
        Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1, 25, self.height - (self:getPercentageFor250(self.current) * self.height) + 3)
        Draw.draw(self.tp_bar_fill, 0, 0)
        Draw.popScissor()
    end
end

function TensionBar:draw()
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.tp_bar_outline, 0, 0)

    self:drawBack()
    self:drawFill()

    self:drawText()

    super.draw(self)
end

return TensionBar