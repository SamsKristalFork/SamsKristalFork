local Testing = {}

function Testing:enter()
    self.stage = Stage()
    self.font = Assets.getFont("main")

    self.state = "MAIN"

    self.soul = self.stage:addChild(EasingSoul(0, 0))
    self.soul.use_parent = true

    self.text = Text("The quick brown fox jumps over the lazy dog.", 0, 240 + 32, {
        ["align"] = "center"
    })
    self.stage:addChild(self.text)
end

function Testing:update()
    self.stage:update()
end

function Testing:draw()
    Draw.resetColor()

    if self.state == "MAIN" then
        Draw.printf("~ テスティング ~", 0, 16, 640, "center")
        Draw.printf("The quick brown fox jumps over the lazy dog.", 0, 240, 640, "center")
    elseif self.state == "GAMEPAD" then
        Draw.setFont(self.font)
        Draw.printf("~ コントローラーテスト ~", 0, 16, 640, "center")
        self:drawGamepad()
    end

    Draw.resetColor()
    local tex = Assets.getTexture("kristal/lancer/wave_9")
    Draw.draw(tex, 320, 480, 0, 2, 2, tex:getWidth() / 2, tex:getHeight())

    self.stage:draw()
end

function Testing:drawGamepad()
    local radius = 40
    local circle_size = 10

    Draw.setColor(COLORS.ltgray)
    Draw.circle("line", 120, 418, radius)

    Draw.setColor(COLORS.white)
    Draw.circle("line", 120 + Input.gamepad_left_x * radius, 418 + Input.gamepad_left_y * radius, circle_size)

    local thing_x, thing_y = Input.getLeftThumbstick()

    Draw.setColor(COLORS.red)
    Draw.circle("line", 120 + thing_x * radius, 418 + thing_y * radius, circle_size)

    Draw.setColor(COLORS.white)

    Draw.setColor(Input.down("gamepad:left") and COLORS.white or COLORS.gray)
    Draw.print("[<]", 64, 400)
    Draw.setColor(Input.down("gamepad:down") and COLORS.white or COLORS.gray)
    Draw.print("[V]", 104, 426)
    Draw.setColor(Input.down("gamepad:right") and COLORS.white or COLORS.gray)
    Draw.print("[>]", 144, 400)
    Draw.setColor(Input.down("gamepad:up") and COLORS.white or COLORS.gray)
    Draw.print("[^]", 104, 374)


    Draw.setColor(Input.down("left") and COLORS.white or COLORS.gray)
    Draw.print("[<]", 466, 400)
    Draw.setColor(Input.down("down") and COLORS.white or COLORS.gray)
    Draw.print("[V]", 506, 400)
    Draw.setColor(Input.down("right") and COLORS.white or COLORS.gray)
    Draw.print("[>]", 546, 400)
    Draw.setColor(Input.down("up") and COLORS.white or COLORS.gray)
    Draw.print("[^]", 506, 374)
end

return Testing
