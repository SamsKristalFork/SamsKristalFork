---@class TensionBar : Object
---@overload fun(...) : TensionBar
local TensionBar, super = Class(Object)

function TensionBar:init(x, y, dont_animate)
    if not Game:getConfig("oldTensionBar") then
        self.textures = {
            ["fill"]    = Assets.getTexture("ui/battle/tp_bar_fill"),
            ["outline"] = Assets.getTexture("ui/battle/tp_bar_outline")
        }
    else
        self.textures = {
            ["fill"]    = Assets.getTexture("ui/battle/tp_bar_fill_old"),
            ["outline"] = Assets.getTexture("ui/battle/tp_bar_outline_old")
        }
    end
    self.textures["text"] = Assets.getTexture("ui/battle/tp_text")
    self.font = Assets.getFont("main")

    if not x then
        if Game.battle then
            local left_bound,_,_,_ = Game.battle.camera:getRect()
            x = left_bound - self.textures.outline:getWidth()
        elseif Game.world then
            local left_bound,_,_,_ = Game.world.camera:getRect()
            x = left_bound - self.textures.outline:getWidth()
        end
    end

    super.init(self, x, y or 40)

    self.width = self.textures.outline:getWidth()
    self.height = self.textures.outline:getHeight()

    self.shown_x = self.width + 13

    self.parallax_x = 0
    self.parallax_y = 0

    self.apparent = 0
    self.current = 0

    self.animation_state = (not dont_animate and "IN") or "NONE"
    self.animation_progress = 0

    self.preview_timer = 0
    self.preview_amount = 0

    self.shown = false
end

function TensionBar:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Tension: "  .. Utils.round(self:getPercentageFor(Game:getTension()) * 100) .. "%")
    table.insert(info, "Apparent: " .. self.apparent)
    table.insert(info, "Current: "  .. self.current)
    return info
end

function TensionBar:getTexture(texture)
    if texture and self.textures[texture] then
        return self.textures[texture]
    end
end

function TensionBar:getTension250()
    return self:getPercentageFor(Game:getTension()) * 250
end

function TensionBar:getPercentageFor(amount)
    return amount / Game:getMaxTension()
end

function TensionBar:getPercentageFor250(amount)
    return amount / 250
end

function TensionBar:getMultipliedPercentageFor250(amount)
    return (amount / 250) * 100
end

function TensionBar:getCurrentPercent() -- rename
    return math.floor(self:getMultipliedPercentageFor250(self.apparent))
end

function TensionBar:isMax()
    return self:getCurrentPercent() >= 100
end

function TensionBar:setPreviewAmount(amount)
    self.preview_amount = amount
end

function TensionBar:show()
    if not self.shown then
        self.shown = true
        self.x = self.init_x
        self.animation_state = "IN"
        self.animation_progress = 0
    end
end

function TensionBar:hide()
    if self.shown then
        self.shown = false
        self.x = self.shown_x
        self.animation_state = "OUT"
        self.animation_progress = 0
    end
end

function TensionBar:updateSlideIn()
    if self.animation_state == "IN" then
        self.animation_progress = self.animation_progress + DTMULT
        local max_time = 12

        if self.animation_progress > max_time then
            self.animation_progress = 0
            self.animation_state = "NONE"
            self.x = self.shown_x
            return
        end

        self.x = Utils.ease(self.init_x, self.shown_x, self.animation_progress / max_time, "out-cubic")
    elseif self.animation_state == "OUT" then
        self.animation_progress = self.animation_progress + DTMULT
        local max_time = 9

        if self.animation_progress > max_time then
            self.animation_progress = 0
            self.animation_state = "NONE"
            self.x = self.init_x
            return
        end

        self.x = Utils.ease(self.shown_x, self.init_x, self.animation_progress / max_time, "out-cubic")
    end
end

function TensionBar:updateAmount()
    if (math.abs((self.apparent - self:getTension250())) < 20) then
        self.apparent = self:getTension250()
    elseif (self.apparent < self:getTension250()) then
        self.apparent = self.apparent + (20 * DTMULT)
    elseif (self.apparent > self:getTension250()) then
        self.apparent = self.apparent - (20 * DTMULT)
    end
    if (self.apparent ~= self.current) then
        local difference = self.apparent - self.current

        if difference > 0 then
            self.current = self.current + (2 * DTMULT)
        end
        if difference > 10 then
            self.current = self.current + (2 * DTMULT)
        end
        if difference > 25 then
            self.current = self.current + (3 * DTMULT)
        end
        if difference > 50 then
            self.current = self.current + (4 * DTMULT)
        end
        if difference > 100 then
            self.current = self.current + (5 * DTMULT)
        end
        if difference < 0 then
            self.current = self.current - (2 * DTMULT)
        end
        if difference < -10 then
            self.current = self.current - (2 * DTMULT)
        end
        if difference < -25 then
            self.current = self.current - (3 * DTMULT)
        end
        if difference < -50 then
            self.current = self.current - (4 * DTMULT)
        end
        if difference < -100 then
            self.current = self.current - (5 * DTMULT)
        end
        if math.abs(difference) < 3 then
            self.current = self.apparent
        end
    end

    if self.preview_amount > 0 then
        self.preview_timer = self.preview_timer + DTMULT
    end
end

function TensionBar:update()
    self:updateSlideIn()
    self:updateAmount()

    super.update(self)
end

function TensionBar:drawBar()
    self:drawOutline()

    self:drawBack()
    self:drawFill()
    self:drawPreview()
    self:drawMarker()

    self:drawTPText()
    self:drawText()
end

function TensionBar:drawOutline()
    Draw.resetColor()
    Draw.draw(self:getTexture("outline"))
end

function TensionBar:drawTPText()
    Draw.resetColor()
    Draw.draw(self:getTexture("text"), -30, 30)
end

function TensionBar:drawText()
    if not self:isMax() then
        self:drawNormalText()
    else
        self:drawMaxText()
    end
end

function TensionBar:drawNormalText()
    Draw.setFont(self.font)
    Draw.print(tostring(math.floor(self:getMultipliedPercentageFor250(self.apparent))), -30, 70)
    Draw.print("%", -25, 95)
end

function TensionBar:drawMaxText()
    Draw.setFont(self.font)
    Draw.setColor(PALETTE["tension_maxtext"])

    Draw.print("M", -28, 70)
    Draw.print("A", -24, 90)
    Draw.print("X", -20, 110)
end

function TensionBar:drawBack()
    Draw.setColor(PALETTE["tension_back"])
    Draw.pushScissor()
    Draw.scissorPoints(0, 0, self.width, self.height - (self:getPercentageFor250(self.current) * self.height) + 1)
    Draw.draw(self:getTexture("fill"))
    Draw.popScissor()
end

function TensionBar:drawFill()
    if self.current > 0 then
        local fill_texture = self:getTexture("fill")

        if (self.apparent < self.current) then
            Draw.setColor(PALETTE["tension_decrease"])
            Draw.pushScissor()
            Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1, self.width, self.height)
            Draw.draw(fill_texture)
            Draw.popScissor()
    
            Draw.setColor(PALETTE["tension_fill"])
            Draw.pushScissor()
            Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.apparent) * self.height) + 1 + (self:getPercentageFor(self.preview_amount) * self.height), self.width, self.height)
            Draw.draw(fill_texture)
            Draw.popScissor()
        elseif (self.apparent > self.current) then
            Draw.setColor(PALETTE["tension_increase"])
            Draw.pushScissor()
            Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.apparent) * self.height) + 1, self.width, self.height)
            Draw.draw(fill_texture)
            Draw.popScissor()
    
            Draw.setColor(PALETTE["tension_fill"])
            if self:isMax() then
                Draw.setColor(PALETTE["tension_max"])
            end
            Draw.pushScissor()
            Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1 + (self:getPercentageFor(self.preview_amount) * self.height), self.width, self.height)
            Draw.draw(fill_texture)
            Draw.popScissor()
        elseif (self.apparent == self.current) then
            Draw.setColor(PALETTE["tension_fill"])
            if self:isMax() then
                Draw.setColor(PALETTE["tension_max"])
            end
            Draw.pushScissor()
            Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1 + (self:getPercentageFor(self.preview_amount) * self.height), self.width, self.height)
            Draw.draw(fill_texture)
            Draw.popScissor()
        end
    end
end

function TensionBar:drawPreview()
    if self.preview_amount > 0 then
        local fill_texture = self:getTexture("fill")

        local flash_color = PALETTE["tension_flash"]
        flash_color[4] = math.abs((math.sin((self.preview_timer / 8)) * 0.5)) + 0.2

        local current_height = self.height - (self:getPercentageFor250(self.current) * self.height)
        local preview_height = current_height + (self:getPercentageFor(self.preview_amount) * self.height)
        -- Note: causes a visual bug?
        if preview_height > (self.height - 1) then
            preview_height = self.height - 1
            flash_color = {COLORS.dkgray[1], COLORS.dkgray[2], COLORS.dkgray[3], 0.7}
        end

        Draw.pushScissor()
        Draw.scissorPoints(0, preview_height + 1, self.width, current_height + 1)

        local r, g, b, _ = Draw.getColor()
        Draw.setColor(r, g, b, 0.7)
        Draw.draw(fill_texture)

        Draw.setColor(flash_color)
        Draw.draw(fill_texture)

        Draw.popScissor()
    end
end

function TensionBar:drawMarker()
    -- this can sometimes be the wrong height somehow
    if ((self.apparent > 20) and (self.apparent < 250)) then
        Draw.setColor(PALETTE["tension_marker"])
        Draw.pushScissor()
        Draw.scissorPoints(0, self.height - (self:getPercentageFor250(self.current) * self.height) + 1, self.width, self.height - (self:getPercentageFor250(self.current) * self.height) + 3)
        Draw.draw(self:getTexture("fill"))
        Draw.popScissor()
    end
end

function TensionBar:draw()
    self:drawBar()
    super.draw(self)
end

return TensionBar