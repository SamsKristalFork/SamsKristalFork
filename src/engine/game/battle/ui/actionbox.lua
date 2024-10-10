---@class ActionBox : Object
---@overload fun(...) : ActionBox
local ActionBox, super = Class(Object)

function ActionBox:init(x, y, index, battler)
    super.init(self, x, y)

    if Game.battle then
        self.battle = Game.battle
        self.battle_ui = self.battle.ui
    end

    self.index = index
    self.battler = battler

    self.selected_button = 1

    self.button_spacing = 35

    self:createDisplay()
    self:createButtons()

    self.name_font = Assets.getFont("name")

    self.selection_siner = 0
end

function ActionBox:createDisplay()
    self.display = ActionBoxDisplay(self)
    self.display.layer = 1
    self:addChild(self.display)
    self.display_offset = 0

    self:createHeadSprite()
    self:createNameSprite()
    self:createHPSprite()
end

function ActionBox:createHeadSprite()
    self.head_offset_x, self.head_offset_y = self.battler.chara:getHeadIconOffset()

    self.head_sprite = Sprite(self.battler.chara:getHeadIcons().."/"..self.battler:getHeadIcon(), 13 + self.head_offset_x, 11 + self.head_offset_y)
    if not self.head_sprite:getTexture() then
        self.head_sprite:setSprite(self.battler.chara:getHeadIcons().."/head")
    end

    self.force_head_sprite = false

    self.display:addChild(self.head_sprite)
end

function ActionBox:createNameSprite()
    if self.battler.chara:getNameSprite() then
        self.name_sprite = Sprite(self.battler.chara:getNameSprite(), 51, 14)
        self.display:addChild(self.name_sprite)
    end
end

function ActionBox:createHPSprite()
    self.hp_sprite = Sprite("ui/hp", 109, 22)
    self.display:addChild(self.hp_sprite)
end

function ActionBox:getButtons()
    local button_types = {"fight", "act", "magic", "item", "spare", "defend"}

    if not self.battler.chara:hasAct() then Utils.removeFromTable(button_types, "act") end
    if not self.battler.chara:hasSpells() then Utils.removeFromTable(button_types, "magic") end

--[[     for lib_id,_ in Kristal.iterLibraries() do
        btn_types = Kristal.libCall(lib_id, "getActionButtons", self.battler, btn_types) or btn_types
    end
    btn_types = Kristal.modCall("getActionButtons", self.battler, btn_types) or btn_types ]]

    return button_types
end

function ActionBox:getButtonOrigin(button_count)
    local origin = (213 / 2) - ((button_count - 1) * 35 / 2) - 1
    if (button_count <= 5) and Game:getConfig("oldUIPositions") then
        origin = origin - 5.5
    end
    return origin
end

function ActionBox:getButtonSpacing()
    return self.button_spacing
end

function ActionBox:createButtons()
    for _,button in ipairs(self.buttons or {}) do
        button:remove()
    end

    self.buttons = {}

    local button_types = self:getButtons()

    local start_x = self:getButtonOrigin(#button_types)

    for i, button_type in ipairs(button_types) do
        if type(button_type) == "string" then
            local button = ActionButton(button_type, self.battler, math.floor(start_x + ((i - 1) * self:getButtonSpacing())) + 0.5, 21)
            button.actbox = self
            table.insert(self.buttons, button)
            self:addChild(button)
        elseif type(button_type) ~= "boolean" then -- nothing if a boolean value, used to create an empty space
            button_type:setPosition(math.floor(start_x + ((i - 1) * self:getButtonSpacing())) + 0.5, 21)
            button_type.battler = self.battler
            button_type.actbox = self
            table.insert(self.buttons, button_type)
            self:addChild(button_type)
        end
    end

    self.selected_button = Utils.clamp(self.selected_button, 1, #self.buttons)
end

function ActionBox:setHeadIcon(icon)
    self.force_head_sprite = true

    local full_icon = self.battler.chara:getHeadIcons().."/"..icon
    if self.head_sprite:hasSprite(full_icon) then
        self.head_sprite:setSprite(full_icon)
    else
        self.head_sprite:setSprite(self.battler.chara:getHeadIcons().."/head")
    end
end

function ActionBox:resetHeadIcon()
    self.force_head_sprite = false

    local full_icon = self.battler.chara:getHeadIcons().."/"..self.battler:getHeadIcon()
    if self.head_sprite:hasSprite(full_icon) then
        self.head_sprite:setSprite(full_icon)
    else
        self.head_sprite:setSprite(self.battler.chara:getHeadIcons().."/head")
    end
end

function ActionBox:reset()
    self.selected_button = 1
    self:resetHeadIcon()
end

function ActionBox:update()
    self.selection_siner = self.selection_siner + (2 * DTMULT)

    self:updateDisplayPosition()
    self:updateHeadSpritePosition()
    self:updateNameSpritePosition()
    self:updateHPSpritePosition()
    self:updateHeadSprite()
    self:updateButtons()

    super.update(self)
end

function ActionBox:updateDisplayPosition()
    if self.battle.current_selecting_index == self.index then
        -- "what's an easing function?" -toby
        if self.display.y > -32 then self.display.y = self.display.y - 2 * DTMULT end
        if self.display.y > -24 then self.display.y = self.display.y - 4 * DTMULT end
        if self.display.y > -16 then self.display.y = self.display.y - 6 * DTMULT end
        if self.display.y > -8  then self.display.y = self.display.y - 8 * DTMULT end
        if self.display.y < -32 then self.display.y = -32 end
    elseif self.display.y < -14 then
        self.display.y = self.display.y + 15 * DTMULT
    else
        self.display.y = 0
    end
end

function ActionBox:updateHeadSpritePosition()
    self.head_sprite.y = 11 - self.display_offset + self.head_offset_y
end

function ActionBox:updateNameSpritePosition()
    if self.name_sprite then
        self.name_sprite.y = 14 - self.display_offset
    end
end

function ActionBox:updateHPSpritePosition()
    self.hp_sprite.y = 22 - self.display_offset
end

function ActionBox:updateHeadSprite()
    if not self.force_head_sprite then
        local current_head = self.battler.chara:getHeadIcons().."/"..self.battler:getHeadIcon()
        if not self.head_sprite:hasSprite(current_head) then
            current_head = self.battler.chara:getHeadIcons().."/head"
        end

        if not self.head_sprite:isSprite(current_head) then
            self.head_sprite:setSprite(current_head)
        end
    end
end

function ActionBox:updateButtons()
    for i, button in ipairs(self.buttons) do
        if (self.battle.current_selecting_index == self.index) then
            button.selectable = true
            button.hovered = (self.selected_button == i)
        else
            button.selectable = false
            button.hovered = false
        end
    end
end

function ActionBox:draw()
    self:drawSelectionMatrix()
    self:drawBorders()

    super.draw(self)

    self:drawNameText()
end

function ActionBox:drawBorders()
    if self.battle.current_selecting_index == self.index then
        Draw.setColor(self.battler.chara:getColor())
        Draw.setLineWidth(2)
        Draw.line(1  , 2, 1,   37)
        Draw.line(Game:getConfig("oldUIPositions") and 211 or 212, 2, Game:getConfig("oldUIPositions") and 211 or 212, 37)
        Draw.line(0  , 6, 212, 6 )
    end
end

function ActionBox:drawSelectionMatrix()
    -- Draw the background of the selection matrix
    Draw.setColor(0, 0, 0, 1)
    Draw.rectangle("fill", 2, 2, 209, 35)

    if self.battle.current_selecting_index == self.index then
        local r,g,b,a = self.battler.chara:getColor()

        for i = 0, 11 do
            local siner = self.selection_siner + (i * (10 * math.pi))

            Draw.setLineWidth(2)
            Draw.setColor(r, g, b, a * math.sin(siner / 60))
            if math.cos(siner / 60) < 0 then
                Draw.line(1 - (math.sin(siner / 60) * 30) + 30, 0, 1 - (math.sin(siner / 60) * 30) + 30, 37)
                Draw.line(211 + (math.sin(siner / 60) * 30) - 30, 0, 211 + (math.sin(siner / 60) * 30) - 30, 37)
            end
        end
    end
end

function ActionBox:drawNameText()
    if not self.name_sprite then
        Draw.setFont(self.name_font)
        Draw.resetColor()

        local name = self.battler.chara:getName():upper()
        local spacing = 5 - name:len()

        local off = 0
        for i = 1, name:len() do
            local letter = name:sub(i, i)
            Draw.print(letter, self.box.x + 51 + off, self.box.y + 14 - self.display_offset - 1)
            off = off + self.name_font:getWidth(letter) + spacing
        end
    end
end

function ActionBox:selectButton()
    self.buttons[self.selected_button]:select()
    self.battle:stopAndPlaySound("ui_select")
end

function ActionBox:unselectButton()
    self.buttons[self.selected_button]:unselect()
end

function ActionBox:nextButton()
    self.selected_button = Utils.clampWrap(self.selected_button + 1, 1, #self.buttons)
    self.battle:stopAndPlaySound("ui_move")
end

function ActionBox:previousButton()
    self.selected_button = Utils.clampWrap(self.selected_button - 1, 1, #self.buttons)
    self.battle:stopAndPlaySound("ui_move")
end

return ActionBox