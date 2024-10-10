---@class ActionButton : Object
---@overload fun(...) : ActionButton
local ActionButton, super = Class(Object)

function ActionButton:init(type, battler, x, y)
    super.init(self, x, y)

    self.battle = Game.battle

    self.type = type
    self.battler = battler

    self.textures = {
        ["idle"]    = Assets.getTexture("ui/battle/btn/"..type),
        ["hovered"] = Assets.getTexture("ui/battle/btn/"..type.."_h"),
        ["special"] = Assets.getTexture("ui/battle/btn/"..type.."_a"),
    }

    self.width = self:getTexture("idle"):getWidth()
    self.height = self:getTexture("idle"):getHeight()

    self:setOriginExact(self.width/2, 13)

    self.hovered = false
    self.selectable = true
end

function ActionButton:getTexture(tex)
    if self.textures[tex] then
        return self.textures[tex]
    end
end

function ActionButton:select()
    if self.battle.encounter:onActionButtonSelect(self.battler, self) then return end
    if Kristal.callEvent(KRISTAL_EVENT.onActionButtonSelect, self.battler, self) then return end
    if self.type == "fight" then
        self:onFightSelected()
    elseif self.type == "act" then
        self:onACTSelected()
    elseif self.type == "magic" then
        self:onSpellSelected()
    elseif self.type == "item" then
        self:onItemSelected()
    elseif self.type == "spare" then
        self:onSpareSelected()
    elseif self.type == "defend" then
        self:onDefendSelected()
    end
end

function ActionButton:onFightSelected()
    self.battle:setState("ENEMYSELECT", "ATTACK")
end

function ActionButton:onACTSelected()
    self.battle:setState("ENEMYSELECT", "ACT")
end

function ActionButton:onSpellSelected()
    self.battle:clearMenuItems()

    if self.battle.encounter.default_xactions and self.battler.chara:hasXAct() then
        local spell = {
            ["name"] = self.battle.enemies[1]:getXAction(self.battler),
            ["target"] = "xact",
            ["id"] = 0,
            ["default"] = true,
            ["party"] = {},
            ["tp"] = 0
        }

        self.battle:addMenuItem({
            ["name"] = self.battler.chara:getXActName() or "X-Action",
            ["tp"] = 0,
            ["color"] = {self.battler.chara:getXActColor()},
            ["data"] = spell,
            ["callback"] = function(menu_item)
                --self.battle.selected_xaction = spell
                self.battle:setState("XACTENEMYSELECT", "SPELL")
            end
        })
    end

    for id, action in ipairs(self.battle.encounter.x_actions) do
        if action.party == self.battler.chara.id then
            local spell = {
                ["name"] = action.name,
                ["target"] = "x_act",
                ["id"] = id,
                ["default"] = false,
                ["party"] = {},
                ["tp"] = action.tp or 0
            }

            self.battle:addMenuItem({
                ["name"] = action.name,
                ["tp"] = action.tp or 0,
                ["description"] = action.description,
                ["color"] = action.color or {1, 1, 1, 1},
                ["data"] = spell,
                ["callback"] = function(menu_item)
                    self.battle.selected_xaction = spell
                    --self.battle:setState("XACTENEMYSELECT", "SPELL")
                end
            })
        end
    end

    for _,spell in ipairs(self.battler.chara:getSpells()) do
        local color = spell.color or {1, 1, 1, 1}
        if spell:hasTag("spare_tired") then
            local has_tired = false
            for _,enemy in ipairs(self.battle:getActiveEnemies()) do
                if enemy.tired then
                    has_tired = true
                    break
                end
            end
            if has_tired then
                color = {0, 178/255, 1, 1}
            end
        end
        self.battle:addMenuItem({
            ["name"] = spell:getName(),
            ["tp"] = spell:getTPCost(self.battler.chara),
            ["unusable"] = not spell:isUsable(self.battler.chara),
            ["description"] = spell:getBattleDescription(),
            ["party"] = spell.party,
            ["color"] = color,
            ["data"] = spell,
            ["callback"] = function(menu_item)
                if not spell.target or spell.target == "none" then
                    self.battle:pushAction("SPELL", nil, menu_item)
                elseif spell.target == "ally" then
                    self.battle:setState("PARTYSELECT", "SPELL", {selected_spell = menu_item})
                elseif spell.target == "enemy" then
                    self.battle:setState("ENEMYSELECT", "SPELL", {selected_spell = menu_item})
                elseif spell.target == "party" then
                    self.battle:pushAction("SPELL", self.battle.party, menu_item)
                elseif spell.target == "enemies" then
                    self.battle:pushAction("SPELL", self.battle:getActiveEnemies(), menu_item)
                end
            end
        })
    end

    self.battle:setState("MENUSELECT", "SPELL")
end

function ActionButton:onItemSelected()
    self.battle:clearMenuItems()
    for i,item in ipairs(Game.inventory:getStorage("items")) do
        self.battle:addMenuItem({
            ["name"] = item:getName(),
            ["unusable"] = item.usable_in ~= "all" and item.usable_in ~= "battle",
            ["description"] = item:getBattleDescription(),
            ["data"] = item,
            ["callback"] = function(menu_item)
                if not item.target or item.target == "none" then
                    self.battle:pushAction("ITEM", nil, menu_item)
                elseif item.target == "ally" then
                    self.battle:setState("PARTYSELECT", "ITEM", {selected_item = menu_item})
                elseif item.target == "enemy" then
                    self.battle:setState("ENEMYSELECT", "ITEM", {selected_item = menu_item})
                elseif item.target == "party" then
                    self.battle:pushAction("ITEM", self.battle.party, menu_item)
                elseif item.target == "enemies" then
                    self.battle:pushAction("ITEM", self.battle:getActiveEnemies(), menu_item)
                end
            end
        })
    end
    if #self.battle:getMenuItems() > 0 then
        self.battle:setState("MENUSELECT", "ITEM")
    end
end

function ActionButton:onSpareSelected()
    self.battle:setState("ENEMYSELECT", "SPARE")
end

function ActionButton:onDefendSelected()
    self.battle:pushAction("DEFEND", nil, {tp = -16})
end

function ActionButton:unselect()
    -- Does nothing, but is overridable
end

function ActionButton:hasSpecial()
    if self.type == "magic" then
        if self.battler then
            local has_tired = false
            for _,enemy in ipairs(self.battle:getActiveEnemies()) do
                if enemy.tired then
                    has_tired = true
                    break
                end
            end
            if has_tired then
                local has_pacify = false
                for _,spell in ipairs(self.battler.chara:getSpells()) do
                    if spell and spell:hasTag("spare_tired") then
                        if spell:isUsable(self.battler.chara) and spell:getTPCost(self.battler.chara) <= Game:getTension() then
                            has_pacify = true
                            break
                        end
                    end
                end
                return has_pacify
            end
        end
    elseif self.type == "spare" then
        for _,enemy in ipairs(self.battle:getActiveEnemies()) do
            if enemy.mercy >= 100 then
                return true
            end
        end
    end
    return false
end

function ActionButton:draw()
    if self.selectable and self.hovered then
        Draw.draw(self:getTexture("hovered") or self:getTexture("idle"))
    else
        Draw.draw(self:getTexture("idle"))
        if self.selectable and self.textures["special"] and self:hasSpecial() then
            local r,g,b,a = self:getDrawColor()
            Draw.setColor(r,g,b,a * (0.4 + math.sin((Kristal.getTime() * 30) / 6) * 0.4))
            Draw.draw(self:getTexture("special"))
        end
    end

    super.draw(self)
end

return ActionButton