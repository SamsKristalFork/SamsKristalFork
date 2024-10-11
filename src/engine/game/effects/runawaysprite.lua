local RunAwaySprite, super = Class(Object)

function RunAwaySprite:init(sprite, direction, distance)
    super.init(self, 0, 0)

    self.sprite = sprite
    self.run_direction = direction or 0
    self.run_distance = distance or 80

    local sox, soy = self.sprite:getScaleOrigin()
    local rox, roy = self.sprite:getRotationOrigin()

    local sox_p, soy_p = self.sprite:localToScreenPos(sox * self.sprite.width, soy * self.sprite.height)
    local rox_p, roy_p = self.sprite:localToScreenPos(rox * self.sprite.width, roy * self.sprite.height)

    self:setScaleOrigin(sox_p / SCREEN_WIDTH, soy_p / SCREEN_HEIGHT)
    self:setRotationOrigin(rox_p / SCREEN_WIDTH, roy_p / SCREEN_HEIGHT)

    self.timer = 0
end

function RunAwaySprite:onAdd(parent)
    local sibling

    local other_parents = self.sprite:getHierarchy()
    for _,parent in ipairs(self:getHierarchy()) do
        for i, object in ipairs(other_parents) do
            if object.parent and object.parent == sparent then
                sibling = object
                break
            end
        end
        if sibling then break end
    end

    if sibling then
        self.layer = sibling.layer - 0.001
    end
end

function RunAwaySprite:applyTransformTo(transform)
    if self.parent then
        transform:reset()
    end
    super.applyTransformTo(self, transform)
end

function RunAwaySprite:update()
    self.timer = self.timer + DTMULT

    if self.timer > self.run_distance then
        self:remove()
    end

    super.update(self)
end

function RunAwaySprite:draw()
    if self.timer > 0 then
        local r, g, b, a = self:getDrawColor()
        for i = 0, self.run_distance do
            local afterimage_alpha = a * 0.4
            Draw.setColor(r, g, b, ((afterimage_alpha - (self.timer / 8)) + (i / 200)))

            local x, y = Utils.transpose(self.run_direction, i * 2)

            love.graphics.push()
            love.graphics.origin()
            love.graphics.applyTransform(self.sprite:getFullTransform())
            Draw.draw(self.sprite.texture, x, y)
            love.graphics.pop()
        end
    end

    super.draw(self)
end

return RunAwaySprite