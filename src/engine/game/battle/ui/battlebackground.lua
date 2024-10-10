local BattleBackground, super = Class(Object)

function BattleBackground:init()
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.progress = 0
    self.offset = 0

    -- IDLE, SHOWING, HIDING
    self.state = "IDLE"
    self.transition_speed = nil

    self.debug_rect = {0, 0, 0, 0}
end

function BattleBackground:fadeIn(speed)
    self.state = "FADEIN"
    self.transition_speed = speed or 1
end

function BattleBackground:fadeOut(speed)
    self.state = "FADEOUT"
    self.transition_speed = speed or 1
end

function BattleBackground:show()
    self.progress = 1
end

function BattleBackground:hide()
    self.progress = 0
end

function BattleBackground:update()
    self.offset = self.offset + DTMULT
    if self.offset > 100 then
        self.offset = self.offset - 100
    end

    if self.state == "FADEIN" then
        self.progress = Utils.approach(self.progress, 1, (self.transition_speed / 10) * DTMULT)
        if self.progress == 1 then
            self.state = "IDLE"
            self.transition_speed = nil
        end
    elseif self.state == "FADEOUT" then
        self.progress = Utils.approach(self.progress, 0, (self.transition_speed / 10) * DTMULT)
        if self.progress == 0 then
            self.state = "IDLE"
            self.transition_speed = nil
        end
    end

    super.update(self)
end

function BattleBackground:drawBackground()
    Draw.setColor(0, 0, 0, self.progress)
    Draw.rectangle("fill", -8, -8, SCREEN_WIDTH + 16, SCREEN_HEIGHT + 16)

    Draw.setLineStyle("rough")
    Draw.setLineWidth(1)

    for i = 2, 16 do
        Draw.setColor(66 / 255, 0, 66 / 255, self.progress / 2)
        Draw.line(0, -210 + (i * 50) + math.floor(self.offset / 2), 640, -210 + (i * 50) + math.floor(self.offset / 2))
        Draw.line(-200 + (i * 50) + math.floor(self.offset / 2), 0, -200 + (i * 50) + math.floor(self.offset / 2), 480)
    end

    for i = 3, 16 do
        Draw.setColor(66 / 255, 0, 66 / 255, self.progress)
        Draw.line(0, -100 + (i * 50) - math.floor(self.offset), 640, -100 + (i * 50) - math.floor(self.offset))
        Draw.line(-100 + (i * 50) - math.floor(self.offset), 0, -100 + (i * 50) - math.floor(self.offset), 480)
    end
end

function BattleBackground:draw()
    self:drawBackground()
    super.draw(self)
end

return BattleBackground