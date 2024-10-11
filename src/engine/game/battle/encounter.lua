--- Encounters detail the setup of unique battles in Kristal, from the enemies that appear to the environment and special mechanics. \
--- Encounter files should be placed inside `scripts/battle/encounters/`.
---
---@class Encounter : Class
---
---@field text                  string
---
---@field background            boolean
---@field hide_world            boolean
---
---@field music                 string?
---
---@field default_xactions      boolean
---
---@field no_end_message        boolean
---
---@field queued_enemy_spawns   table
---
---@field defeated_enemies      table
---
---@overload fun(...) : Encounter
local Encounter = Class()

function Encounter:init()
    -- Text that will be displayed when the battle starts
    self.first_text = "* A skirmish breaks out!"

    -- Whether the default grid background is drawn
    self.background = true
    -- If enabled, hides the world even if the default background is disabled
    self.hide_world = false

    -- The music used for this encounter
    self.music = "battle"

    -- Whether characters have the X-Action option in their spell menu
    self.default_x_actions = Game:getConfig("partyActions")

    self.enemy_base_x = 550
    self.enemy_base_y = 200
    self.enemy_x_separation = 10
    self.enemy_y_separation = 45

    -- Should the battle skip the YOU WON! text?
    self.no_end_message = false

    -- Table used to spawn enemies when the battle exists, if this encounter is created before
    self.queued_enemy_spawns = {}

    -- A copy of Battle.defeated_enemies, used to determine how an enemy has been defeated.
    self.defeated_enemies = nil

    self.x_actions = {}
end

-- Callbacks

--- *(Override)* Called in [`Battle:postInit()`](lua://Battle.postInit). \
--- *If this function returns `true`, then the battle will not override any state changes made here.*
---@return boolean?
function Encounter:onBattleInit() end
--- *(Override)* Called when the battle enters the `"INTRO"` state and the characters do their starting animations.
function Encounter:onBattleStart() end
--- *(Override)* Called when the battle is completed and the victory text (if presesnt) is advanced, just before the transition out.
function Encounter:onBattleEnd() end

--- *(Override)* Called at the start of each new turn, just before the player starts choosing actions.
function Encounter:onTurnStart() end
--- *(Override)* Called at the end of each turn, at the same time all waves end.
function Encounter:onTurnEnd() end

--- *(Override)* Called when the party start performing their actions.
function Encounter:onActionsStart() end
--- *(Override)* Called when the party finish performing their actions.
function Encounter:onActionsEnd() end

--- *(Override)* Called when a character's turn selecting actions begins.
---@param battler   PartyBattler    The battler whose turn it is.
---@param undo      boolean         Whether this character's turn was entered by undoing their previously selected action.
function Encounter:onPartyTurn(battler, index, undo) end

--- *(Override)* Called when [`Battle:setState()`](lua://Battle.setState) is called. \
--- *Changing the state to something other than `new`, or returning `true` will stop the standard state change code for this state change from occurring.*
---@param old string
---@param new string
---@return boolean?
function Encounter:beforeStateChange(old, new) end
--- *(Override)* Called when [`Battle:setState()`](lua://Battle.setState) is called, after any state change code has run.
---@param old string
---@param new string
function Encounter:onStateChange(old, new) end

--- *(Override)* Called when an [`ActionButton`](lua://ActionButton.init) is selected.
---@param battler   PartyBattler
---@param button    ActionButton
function Encounter:onActionButtonSelect(battler, button) end

--- *(Override)* Called when an item in a menu is selected (confirm key pressed).
---@param state_reason string       The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param item          table       A table of information representing the menu item.
---@param can_select    boolean     Whether the item is actually selectable or is greyed out.
function Encounter:onMenuSelect(state_reason, item, can_select) end
--- *(Override)* Called when the player backs out of a menu.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param item          table   A table of information representing the menu item that was being hovered over.
function Encounter:onMenuCancel(state_reason, item) end

--- *(Override)* Called when the player selects an enemy in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param enemy_index   integer The index of the selected enemy on the menu.
function Encounter:onEnemySelect(state_reason, enemy_index) end
--- *(Override)* Called when the player backs out of an enemyselect menu in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param enemy_index   integer The index of the selected enemy on the menu.
function Encounter:onEnemyCancel(state_reason, enemy_index) end

--- *(Override)* Called when the player selects a party member in a partyselect menu in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param party_index   integer The index of the selected enemy on the menu.
function Encounter:onPartySelect(state_reason, party_index) end
--- *(Override)* Called when the player backs out of a partyselect menu in battle.
---@param state_reason  string  The current value of [`Battle.state_reason`](lua://Battle.state_reason)
---@param party_index   number  The index of the selected enemy on the menu.
function Encounter:onPartyCancel(state_reason, party_index) end

--- *(Override)* Called just before a Game Over. \
--- *If this function returns `true`, then the Game Over will not occur*
---@return boolean?
function Encounter:onGameOver() end
--- *(Override)* Called just before returning to the world.
---@param events Character  A list of enemy events in the world that are linked to the enemies in battle.
function Encounter:onReturnToWorld(events) end

--- *(Override)* Called whenever dialogue is about to start, if this returns a value, it will be unpacked and passed
--- into [`Battle:startCutscene(...)`](lua://Battle.startCutscene), as an alternative to standard dialogue.
---@return table?
function Encounter:getDialogueCutscene() end

---@param money integer     Current victory money based on normal money calculations
---@return integer? money
function Encounter:getVictoryMoney(money) end
---@param xp integer        Current victory xp based on normal xp calculations
---@return integer? xp
function Encounter:getVictoryXP(xp) end
---@param text  string      Current victory text
---@param money integer     Money earned on victory
---@param xp    integer     XP earned on victory
---@return string? text
function Encounter:getVictoryText(text, money, xp) end

function Encounter:update() end

--- *(Override)* Called before anything has been rendered each frame. Usable to draw custom backgrounds for specific encounters.
---@param fade number   The opacity of the background when fading in/out of the world.
function Encounter:draw(fade) end

function Encounter:createBackground()
    return BattleBackground()
end

-- Functions

function Encounter:addEnemy(enemy, x, y, ...)
    if type(enemy) == "string" then
        enemy = Registry.createEnemy(enemy, ...)
    end
    enemy.encounter = self
    table.insert(self.queued_enemy_spawns, {enemy_object = enemy, x = x, y = y})
    return enemy
end

function Encounter:getEnemyPosition(index)
    return self.enemy_base_x + (self.enemy_x_separation * (index - 1)), self.enemy_base_y + (self.enemy_y_separation * (index - 1))
end

function Encounter:alignEnemiesInTransition(enemies)
    if Game.state == "BATTLE" and Game.battle then
        for i, enemy in ipairs(enemies) do
            local target_x, target_y = self:getEnemyPosition(i)
            
            for j = 1, #enemies - i do
                target_x = target_x - self.enemy_x_separation
                target_y = target_y - self.enemy_y_separation
            end
    
            Game.battle.transition_targets.enemies[enemy] = {target_x, target_y}
            enemy.x = SCREEN_WIDTH + 200
        end
    end
end

function Encounter:alignEnemies(enemies)
    enemies = enemies or self.queued_enemy_spawns

    -- this is dumb
    for i, enemy in ipairs(enemies) do
        enemy.x, enemy.y = self:getEnemyPosition(i)

        for j = 1, #enemies - i do
            enemy.x = enemy.x - self.enemy_x_separation
            enemy.y = enemy.y - self.enemy_y_separation
        end
    end
end

function Encounter:getFirstEncounterText()
    return self.first_text
end

--- *(Override)* Called to receive the encounter text to be displayed each turn. (Not called on turn one, [`text`](lua://Encounter.text) is used instead.) \
--- By default, gets an encounter text from a random enemy, falling back on the encounter's [encounter `text`](lua://Encounter.text) if none have encounter text.
---@return string
function Encounter:getEncounterText()
    local enemies = Game.battle:getActiveEnemies()
    local enemy = Utils.pick(enemies, function(v)
        if not v.text then
            return true
        else
            return #v.text > 0
        end
    end)
    if enemy then
        return enemy:getEncounterText()
    else
        return self.text
    end
end

--- *(Override)* Retrieves the waves to be used for the next defending phase. \
--- By default, iterates through all active enemies and selects one wave each using [`EnemyBattler:selectWave()`](lua://EnemyBattler.selectWave)
---@return Wave[]
function Encounter:getNextWaves()
    local waves = {}
    for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
        local wave = enemy:selectWave()
        if wave then
            table.insert(waves, wave)
        end
    end
    return waves
end

--- *(Override)* Gets the position the party member at `index` should stand at in this battle.
---@param index integer The index of the party member in [`Game.battle.party`](lua://Battle.party).
---@return number x
---@return number y
function Encounter:getPartyPosition(index)
    local x, y = 0, 0
    if #Game.battle.party == 1 then
        x = 80
        y = 140
    elseif #Game.battle.party == 2 then
        x = 80
        y = 100 + (80 * (index - 1))
    elseif #Game.battle.party == 3 then
        x = 80
        y = 50 + (80 * (index - 1))
    end

    local battler = Game.battle.party[index]
    local ox, oy = battler.chara:getBattleOffset()
    x = x + (battler.actor:getWidth()/2 + ox) * 2
    y = y + (battler.actor:getHeight()  + oy) * 2
    return x, y
end

---@return integer
---@return integer
---@return integer
---@return integer
function Encounter:getSoulColor()
    return Game:getSoulColor()
end

--- *(Override)* Gets the position that the soul will appear at when starting waves.
---@return integer x
---@return integer y
function Encounter:getSoulSpawnLocation()
    local main_chara = Game:getSoulPartyMember()

    if main_chara and main_chara:getSoulPriority() >= 0 then
        local battler = Game.battle.party[Game.battle:getPartyIndex(main_chara.id)]

        if battler then
            if main_chara.soul_offset then
                return battler:localToScreenPos(main_chara.soul_offset[1], main_chara.soul_offset[2])
            else
                return battler:localToScreenPos((battler.sprite.width/2) - 4.5, battler.sprite.height/2)
            end
        end
    end
    return -9, -9
end

function Encounter:onDialogueEnd() end

function Encounter:onWavesDone() end

--- *(Override)* Creates the soul being used this battle (Called at the start of the first wave)
--- By default, returns the regular (red) soul.
---@param x         number  The x-coordinate the soul should spawn at.
---@param y         number  The y-coordinate the soul should spawn at.
---@param color?    table   A custom color for the soul, that should override its default.
---@return Soul
function Encounter:createSoul(x, y, color)
    return Soul(x, y, color)
end

function Encounter:registerXAction(party, name, description, tp, highlight, extra)
    local x_action = {
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["color"] = {Game.battle.party[Game.battle:getPartyIndex(party)].chara:getXActionColor()},
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = false
    }
    table.insert(Utils.merge(self.x_actions, extra), x_action)
end

---@return boolean
function Encounter:canDeepCopy()
    return false
end

---@return table defeated_enemies A table indicating the enemies defeated in battle.
function Encounter:getDefeatedEnemies()
    return self.defeated_enemies or Game.battle.defeated_enemies
end

---@param flag  string
---@param value any
function Encounter:setFlag(flag, value)
    Game:setFlag("encounter#"..self.id..":"..flag, value)
end

---@param flag      string
---@param default?  any
---@return any
function Encounter:getFlag(flag, default)
    return Game:getFlag("encounter#"..self.id..":"..flag, default)
end

--- Increments a numerical flag by `amount`.
---@param flag      string
---@param amount?   number  (Defaults to `1`)
---@return number
function Encounter:addFlag(flag, amount)
    return Game:addFlag("encounter#"..self.id..":"..flag, amount)
end

return Encounter