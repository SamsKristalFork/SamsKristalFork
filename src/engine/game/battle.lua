local Battle, super = Class(Object)

function Battle:init()
    super.init(self)

    self.sounds = {
        ["ui_move"]   = Assets.newSound("ui_move"),
        ["ui_select"] = Assets.newSound("ui_select")
    }

    self.encounter_context = nil
    self.used_violence = false
    self.seen_first_encounter_text = false

    self.money = 0
    self.xp = 0
    self.turn_count = 0

    self.world_characters = {
        ["party"] = {},
        ["enemies"] = {}
    }

    self.world_positions = {
        ["party"] = {},
        ["enemies"] = {}
    }

    self.transition_targets = {
        ["party"] = {},
        ["enemies"] = {}
    }

    self.darken = false

    self.party = {}
    self:createPartyBattlers()

    self.ready_members_stack = {}
    self.ready_actions_stack = {}

    self.queued_actions = {}
    self.current_actions = {}
    self.current_action_index = 0
    self.currently_processing_action = nil
    self.finished_actions = {}

    self.actions_done_timer = 0

    self.attackers = {}
    self.normal_attackers = {}
    self.auto_attackers = {}

    self.enemies = {}
    self.all_enemies = {}

    self.enemy_list = {}

    self.enemies_to_remove = {}
    self.removed_enemies = {}

    self.waves = {}
    self.wave_length = 0
    self.wave_timer = 0
    self.finished_waves = false

    self.background = nil
    self.ui = nil
    self.tension_bar = nil

    self.state = "NONE"
    self.state_reason = nil
    self.state_vars = {}

    self.substate = "NONE"
    self.substate_reason = nil

    self.current_encounter_text = nil

    self.arena = nil
    self.soul = nil
    
    self.music = Music()
    self.camera = Camera(self, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH, SCREEN_HEIGHT, false)

    self.timer = Timer()
    self:addChild(self.timer)

    self.cutscene = nil
end

-- Getters

--- Party

function Battle:getCurrentlySelectingBattler()
    return self.party[self.current_selecting_index]
end

function Battle:getPartyBattler(battler_identifier)
    if type(battler_identifier) == "number" then
        return self.party[battler_identifier]
    elseif type(battler_identifier) == "string" then
        for _,battler in ipairs(self.party) do
            if battler.chara.id == battler_identifier then
                return battler
            end
        end
    end
end

function Battle:getPartyID(battler)
    if isClass(battler) then
        if battler:includes(PartyBattler) then
            return battler.chara.id
        elseif battler:includes(PartyMember) then
            return battler.id
        end
    end
end

function Battle:getPartyIndex(battler)
    if type(battler) == "number" then
        return battler
    elseif type(battler) ~= "string" then
        battler = self:getPartyID(battler)
    end

    for i, ibattler in ipairs(self.party) do
        if ibattler.chara.id == battler then
            return i
        end
    end
end

function Battle:getPartyBattlerActionBox(battler)
    if self.ui then
        return self.ui.action_boxes[self:getPartyIndex(battler)]
    end
end

function Battle:getActiveParty()
    return Utils.filter(self.party, function(party) return not party.is_down end)
end

function Battle:removeEnemy(enemy, defeated)
    table.insert(self.enemies_to_remove, enemy)
    if defeated then
        table.insert(self.removed_enemies, enemy)
    end
end

function Battle:getActiveEnemies()
    return Utils.filter(self.enemies, function(enemy) return not enemy.done_state end)
end

function Battle:getFirstEncounterText()
    if self.encounter then
        return self.encounter:getFirstEncounterText()
    end
end

function Battle:getEncounterText()
    if self.encounter then
        return self.encounter:getEncounterText()
    end
end

-- Functions

--- Misc.

function Battle:parseEnemyIdentifier(id)
    local args = Utils.split(id, ":")
    local enemies = Utils.filter(self.enemies, function(enemy) return enemy.id == args[1] end)
    return enemies[args[2] and tonumber(args[2]) or 1]
end

function Battle:isHighlighted(battler)
    if self.ui then
        return self.ui:isHighlighted(battler)
    else
        return false
    end
end

--- UI

function Battle:isInActionSelect()
    -- event
    if self.ui then
        return self.ui:isInActionSelect()
    end
end 

function Battle:isInMenu()
    -- event
    if self.ui then
        return self.ui:isInMenu()
    end
end

function Battle:setUIEncounterText(text, after)
    if self.ui then
        self.ui:setEncounterText(text, after)
    end
end

function Battle:clearUIEncounterText()
    if self.ui then
        self.ui:clearEncounterText()
    end
end

function Battle:setCurrentEncounterText(instant)
    if self.ui then
        if instant then
            self:setUIEncounterText("[instant]" .. self.current_encounter_text)
        else
            self:setUIEncounterText(self.current_encounter_text)
        end
    end
end

function Battle:refreshEncounterText()
    if self.state == "INTRO" or self.state_reason == "INTRO" or not self.seen_first_encounter_text then
        self.seen_first_encounter_text = true
        self.current_encounter_text = self:getFirstEncounterText()
    else
        self.current_encounter_text = self:getEncounterText()
    end
end

--- Sounds

function Battle:playSound(sound)
    sound = self.sounds[sound]
    sound:play()
end

function Battle:stopSound(sound)
    sound = self.sounds[sound]
    sound:stop()
end

function Battle:stopAndPlaySound(sound)
    sound = self.sounds[sound]
    sound:stop()
    sound:play()
end

--- Camera

function Battle:shakeCamera(x, y, friction)
    self.camera:shake(x, y, friction)
end

-- zoom?

--- Party

function Battle:setCurrentlySelectingBattler(index)
    index = self:getPartyIndex(index)
    self.current_selecting_index = index or 1
    return self.current_selecting_index
end

function Battle:clearActionIcon(battler)
    local action

    if not battler then
        action = self:getCurrentAction()
    else
        action = self:getActionBy(battler)
    end

    if action then
        action.icon = nil
    end
end

function Battle:resetParty()
    for _,battler in ipairs(self.party) do
        battler:setSleeping(false)
        battler.defending = false
        battler.action = nil

        battler.chara:resetBuffs()

        if battler.chara:getHealth() <= 0 then
            battler:revive()
            battler.chara:setHealth(battler.chara:autoHealAmount())
        end

        self:getPartyBattlerActionBox(battler):resetHeadIcon()
    end
end

function Battle:nextParty()
    -- events?
    table.insert(self.ready_members_stack, self.current_selecting_index)
    table.insert(self.ready_actions_stack, Utils.copy(self.queued_actions))

    local ready = true
    local previous_selecting_index = self.current_selecting_index
    self.current_selecting_index = (self.current_selecting_index % #self.party) + 1
    while self.current_selecting_index ~= previous_selecting_index do
        if not self:hasQueuedAction(self.current_selecting_index) and self:getCurrentlySelectingBattler():isActive() then
            ready = false
            break
        end
        self.current_selecting_index = (self.current_selecting_index % #self.party) + 1
    end

    if ready then
        self.ready_members_stack = {}
        self.ready_actions_stack = {}
        self:startProcessingActions()
    else
        -- not sure if i like this
        if self.state ~= "ACTIONSELECT" then
            self:setState("ACTIONSELECT")
            self:setCurrentEncounterText(true)
        end
        local next_battler = self:getCurrentlySelectingBattler()

        -- event
        next_battler.chara:onTurn(next_battler, false)
        self.encounter:onPartyTurn(next_battler, self.current_selecting_index, false)
    end
end

function Battle:previousParty()
    if #self.ready_members_stack == 0 then return end

    local members_stack = self.ready_members_stack
    local actions_stack = self.ready_actions_stack

    self.current_selecting_index = members_stack[#members_stack] or 1
    local restored_actions = actions_stack[#actions_stack - 1] or {}

    for i, battler in ipairs(self.party) do
        local current_action = self.queued_actions[i]
        local restored_action = restored_actions[i]
        if current_action ~= restored_action then
            if current_action.cancellable == false then
                restored_actions[i] = current_action
            else
                if current_action then
                    self:removeAction(current_action)
                end
                if restored_action then
                    self:removeAction(restored_action)
                end
            end
        end
    end

    -- this should still just be a reference
    actions_stack[#actions_stack - 1] = restored_actions

    table.remove(self.ready_members_stack, #self.ready_members_stack)
    table.remove(self.ready_actions_stack, #self.ready_actions_stack)

    local battler = self:getCurrentlySelectingBattler()
    -- event
    battler.chara:onTurn(battler, true)
    self.encounter:onPartyTurn(next_battler, self.current_selecting_index, true)
end

function Battle:resetCurrentlySelectingIndex()
    self.current_selecting_index = 0
    while not self:getCurrentlySelectingBattler() or not (self:getCurrentlySelectingBattler():isActive()) do
        self.current_selecting_index = self.current_selecting_index + 1
        if self.current_selecting_index > #self.party then
            Kristal.Console:warn("WARNING: Nobody up! This shouldn't happen...")
            self.current_selecting_index = 1
            break
        end
    end
end

function Battle:resetPartyPositionFor(battler)
    battler = self:getPartyIndex(battler)
    local target_x, target_y = self.encounter:getPartyPosition(battler)
    battler:setPosition(target_x, target_y)
end

--- Setup

function Battle:createPartyBattler(member, x, y)
    if not x or not y then
        x, y = SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2
    end

    local battler = PartyBattler(member, x, y)
    self:addChild(battler)

    table.insert(self.party, battler)
    table.insert(self.world_positions.party, {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2})

    --oncreate callback?

    return battler
end

function Battle:createPartyBattlerFromCharacter(member, character)
    local x, y = character:getScreenPos()
    local battler = PartyBattler(member, x, y)
    self:addChild(battler)

    table.insert(self.party, battler)
    table.insert(self.world_positions.party, {x, y})

    character.visible = false
    --oncreate callback?

    return battler
end

function Battle:createPartyBattlers()
    for i = 1, math.min(3, #Game.party) do
        local member = Game.party[i]

        local player = Game.world.player
        if player and player.visible and player.actor.id == member:getActor().id then
            self:createPartyBattlerFromCharacter(member, Game.world.player)
        else
            local found = false
            for _,follower in ipairs(Game.world.followers) do
                self:createPartyBattlerFromCharacter(member, follower)
                found = true
                break
            end
            if not found then
                self:createPartyBattler(member)
            end
        end
    end
end

-- Post Initialization

function Battle:postInit(state, encounter)
    self.state = state

    if type(encounter) == "string" then
        self.encounter = Registry.createEncounter(encounter)
    else
        self.encounter = encounter
    end

    if Game.world.music:isPlaying() and self.encounter.music then
        self.resume_world_music = true
        Game.world.music:pause()
    end

    self:createUIElements()
    self:createBackground()

    self:setupPartyTransitionTargets()

    if self.state ~= "TRANSITION" then
        self:resetPartyPositions()
    end

    self:setupEnemies()

    self:startEncounter()
end

function Battle:setupPartyTransitionTargets()
    for i, battler in ipairs(self.party) do
        local target_x, target_y = self.encounter:getPartyPosition(i)
        table.insert(self.transition_targets.party, {target_x, target_y})
    end
end

function Battle:resetPartyPositions()
    for i, battler in ipairs(self.party) do
        local target_x, target_y = self.encounter:getPartyPosition(i)
        battler:setPosition(target_x, target_y)
    end
end

function Battle:addEnemy(enemy, x, y, ...)
    if type(enemy) == "string" then
        enemy = Registry.createEnemy(enemy, ...)
    end

    if not enemy.encounter then enemy.encounter = self.encounter end

    table.insert(self.enemies, enemy)
    table.insert(self.all_enemies, enemy)
    table.insert(self.enemy_list, true)
    self:addChild(enemy)

    if not x and not y then
        self:alignEnemies()
    else
        enemy:setPosition(x, y)
    end
end

function Battle:alignEnemies()
    if self.state == "TRANSITION" then
        self.encounter:alignEnemiesInTransition(self.enemies)
    else
        self.encounter:alignEnemies(self.enemies)
    end
end

function Battle:setupEnemies()
    for i, enemy_spawn in ipairs(self.encounter.queued_enemy_spawns) do
        local enemy, x, y = enemy_spawn.enemy_object, enemy_spawn.x, enemy_spawn.y
        if self.state == "TRANSITION" then
            self.transition_targets.enemies[enemy] = {x or enemy.x, y or enemy.y}
            enemy.x = SCREEN_WIDTH + 200
        end
        self:addEnemy(enemy)
    end

    -- why does this not use indices
    for _,enemy in ipairs(self.enemies) do
        self.world_positions.enemies[enemy] = {enemy.x, enemy.y}
    end
    -- maybe change how Game.encounter_enemies works
    if Game.encounter_enemies then
        for _,from in ipairs(Game.encounter_enemies) do
            if not isClass(from) then
                local enemy = self:parseEnemyIdentifier(from[1])
                from[2].visible = false
                from[2].battler = enemy
                self.world_positions.enemies[enemy] = {from[2]:getScreenPos()}
                self.world_characters.enemies[enemy] = from[2]
                if state == "TRANSITION" then
                    enemy:setPosition(from[2]:getScreenPos())
                end
            else
                for _,enemy in ipairs(self.enemies) do
                    if enemy.actor and from.actor and enemy.actor.id == from.actor.id then
                        from.visible = false
                        from.battler = enemy
                        self.world_positions.enemies[enemy] = {from:getScreenPos()}
                        self.world_characters.enemies[enemy] = from
                        if state == "TRANSITION" then
                            enemy:setPosition(from:getScreenPos())
                        end
                        break
                    end
                end
            end
        end
    end
end

function Battle:startEncounter()
    -- functionify

    for _,battler in ipairs(self.party) do
        battler:setAnimation("battle/transition")
    end

    if self.encounter_context and self.encounter_context:includes(ChaserEnemy) then
        for _,enemy in ipairs(self.encounter_context:getGroupedEnemies(true)) do
            enemy:onEncounterStart(enemy == self.encounter_context, self.encounter)
        end
    end

    if not self.encounter:onBattleInit() then
        -- don't like this
        if self.state ~= "TRANSITION" then   
            if self.background and self.background.show then
                self.background:show()
            end
            
            if self.state ~= "INTRO" then
                self:nextTurn()
            end
        end

        if self.state == "TRANSITION" then
            self:setState(self.state, nil, {afterimage_count = 0, transition_timer = 0})
        else
            self:setState(self.state)
        end
    end
end

-- UI

--- UI Creation

function Battle:createUIElements()
    self:createUI()
    self:createTensionBar()
end

function Battle:createUI()
    self.ui = BattleUI(self, 0, 480)
    self.ui.layer = BATTLE_LAYERS["ui"]
    self:addChild(self.ui)
end

function Battle:createTensionBar()
    self.tension_bar = TensionBar(-25, 40, true)
    self.tension_bar.layer = BATTLE_LAYERS["ui"]
    self:addChild(self.tension_bar)
end

function Battle:createBackground()
    self.background = self.encounter:createBackground()
    self.background.battle = self
    self.background.layer = BATTLE_LAYERS["background"]
    self:addChild(self.background)
end

--- UI Show/Hide

function Battle:showUIElements()
    self:showUI()
    self:showTensionBar()
end

function Battle:hideUIElements()
    self:hideUI()
    self:hideTensionBar()
end

function Battle:showUI()
    if self.ui then
        self.ui:show()
    end
end

function Battle:hideUI()
    if self.ui then
        self.ui:hide()
    end
end

function Battle:showTensionBar()
    if self.tension_bar then
        self.tension_bar:show()
    end
end

function Battle:hideTensionBar()
    if self.tension_bar then
        self.tension_bar:hide()
    end
end

--- UI Menu

function Battle:addMenuItem(item, extra)
    if self.ui and self.ui:getMenu("menu_select") then
        return self.ui:getMenu("menu_select"):addMenuSelectItem(item, extra)
    end
end

function Battle:clearMenuItems()
    if self.ui and self.ui:getMenu("menu_select") then
        self.ui:getMenu("menu_select"):clearMenuSelectItems()
    end
end

function Battle:getMenuItems()
    if self.ui and self.ui:getMenu("menu_select") then
        return self.ui:getMenu("menu_select").items
    end
end

function Battle:resetMenuCursorPositions()
    if self.ui then
        self.ui:resetMenuCursorPositions()
    end
end

--- Action Boxes

function Battle:resetActionBoxes()
    self.ui:resetActionBoxes()
end

-- Turn End

function Battle:nextTurn()
    -- callbacks and events
    self.turn_count = self.turn_count + 1

    local turn_end_result = self:onTurnEnd()
    if turn_end_result then return end

    self:resetActions()
    self:resetActionBoxes()

    self:onEnemiesTurnEnd()
    self:onPartyTurnEnd()

    self:refreshEncounterText()
    self:setCurrentEncounterText()

    if self.soul then
        self:returnSoul()
    end

    self:onTurnStart()

    self:resetCurrentlySelectingIndex()
end

function Battle:onTurnEnd()
    if self.turn_count > 1 then
        if self.encounter:onTurnEnd() then
            return true
        end
        for _,enemy in ipairs(self:getActiveEnemies()) do
            if enemy:onTurnEnd() then
                return true
            end
        end
    end
end

function Battle:onEnemiesTurnEnd()
    for _,enemy in ipairs(self.enemies) do
        enemy.selected_wave = nil
        enemy.hit_count = 0
    end
end

function Battle:onPartyTurnEnd()
    self:resetPartyHitCount()
    self:doPartyAutoHeal()
end

function Battle:resetPartyHitCount()
    for _,battler in ipairs(self.party) do
        battler.hit_count = 0
    end
end

function Battle:doPartyAutoHeal()
    for _,battler in ipairs(self.party) do
        if (battler.chara:getHealth() <= 0) and battler.chara:canAutoHeal() then
            battler:heal(battler.chara:autoHealAmount(), nil, true)
        end
    end
end

function Battle:onTurnStart()
    self.encounter:onTurnStart()

    for _,enemy in ipairs(self:getActiveEnemies()) do
        enemy:onTurnStart()
    end
    -- party version

    if self.battle_ui then
        for _,party in ipairs(self.party) do
            party.chara:onTurnStart(party)
        end
    end

    if self.current_selecting ~= 0 and self.state ~= "ACTIONSELECT" then
        self:setState("ACTIONSELECT")
    end
end

-- States

function Battle:setState(state, reason, vars)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self.state_vars = vars or {}

    self:onStateChange(old, self.state, self.state_reason, self.state_vars)
end

function Battle:doIntro()
    Assets.playSound("impact", 0.7)
    Assets.playSound("weaponpull_fast", 0.8)

    for _,battler in ipairs(self.party) do
        battler:setAnimation("battle/intro")
    end
end

function Battle:onStateChange(old, new, reason, vars)
    --beforebattlestatechange kristal event/encounter callback
    if new == "TRANSITION" then
        self.background:fadeIn()
    elseif new == "INTRO" then
        self.seen_first_encounter_text = false
        self.state_vars["intro_timer"] = 0
        self:doIntro()
        self.encounter:onBattleStart()
    elseif new == "ACTIONSELECT" then
        if self.state_reason == "CANCEL" then
            self:setCurrentEncounterText(true)
        end

    elseif new == "MENUSELECT" then
        self:clearUIEncounterText()
        self:resetMenuCursorPositions()

    elseif new == "ENEMYSELECT" then
        self:clearUIEncounterText()
        self:resetMenuCursorPositions()
    elseif new == "PARTYSELECT" then
        self:clearUIEncounterText()
        self:resetMenuCursorPositions()
    elseif new == "ACTIONS" then
        self:clearUIEncounterText()
        --if self.state_reason ~= "DONTPROCESS" then
            self:tryProcessingNextAction()
        --end
    elseif new == "ATTACKING" then
        self:clearUIEncounterText()

        if #self:getActiveEnemies() > 0 then
            self:setupAttackers()

            if #self.attackers == 0 then
                self.attack_done = true
                self:setState("ACTIONSDONE")
                return
            else
                self.attack_done = false
            end

            self:startAttack(self.normal_attackers)
            self.auto_attack_timer = 0 -- state var
        else
            self.attack_done = true
            self:setState("ACTIONSDONE")
        end
    elseif new == "ENEMYDIALOGUE" then
        self:clearUIEncounterText()
        if not self:checkVictory() then
            self.state_vars["enemy_dialogue_timer"] = 90
            self:showEnemyDialogue()
        end
    elseif new == "DIALOGUEEND" then
        self:clearUIEncounterText()
        self:startDefendingActions()
        if not self.encounter:onDialogueEnd() then
            self:setState("DEFENDINGSTART")
        end
    elseif new == "DEFENDINGSTART" then
--[[         if self.state_reason == "CUTSCENE" then
            self:setState("DEFENDING")
            return
        end ]]


        self:clearUIEncounterText()

        -- function
        self.current_selecting_index = 0

        self:initWaves()

        self.state_vars["defending_start_timer"] = 0
    elseif new == "DEFENDING" then
        self.wave_length = 0
        self.wave_timer = 0

        for _,wave in ipairs(self.waves) do
            wave.encounter = self.encounter

            self.wave_length = math.max(self.wave_length, wave.time)

            wave:onStart()

            wave.active = true
        end
    elseif new == "DEFENDINGEND" then

    elseif new == "VICTORY" then
        self:handleVictory()
    elseif new == "TRANSITIONOUT" then
        self.encounter:onBattleEnd()
        self.current_selecting_index = 0

        self:hideUIElements()

        self.music:fade(0, 20/30)
        self.state_vars["transition_out_timer"] = 10
    end

    self:afterStateChange()
end

function Battle:afterStateChange()
    if self:shouldEndWaves() then
        self:endWaves()
    end
    self.encounter:onStateChange(old, new)
end

function Battle:shouldEndWaves()
    local should_end = true
    if self:shouldRemoveArena() then
        for _,wave in ipairs(self.waves) do
            if wave:beforeEnd() then
                should_end = false
            end
        end
    else
        return false
    end
    return should_end
end

function Battle:endWaves()
    local function exitWaves()
        for _,wave in ipairs(self.waves) do
            wave:onArenaExit()
        end
    end

    self:removeArena()
    for _,battler in ipairs(self.party) do
        battler.targeted = false
    end

    if self:inCutscene() then
        self.cutscene:after(function()
            exitWaves()
            if self.state_reason == "WAVEENDED" then
                self:nextTurn()
            end
        end)
    else
        -- why use a timer here?
        self.timer:after(15/30, function()
            exitWaves()
            if self.state_reason == "WAVEENDED" then
                self:nextTurn()
            end
        end)
    end

    self:clearWaves()
end

function Battle:setupAttackers()
    for i, battler in ipairs(self.party) do
        local action = self.queued_actions[i]
        if action then
            local type = action.action_type
            if type == "ATTACK" then
                table.insert(self.attackers, battler)
                table.insert(self.normal_attackers, battler)
            elseif type == "AUTOATTACK" then
                table.insert(self.attackers, battler)
                table.insert(self.auto_attackers, battler)
            end
        end
    end
end

function Battle:startAttack(attackers)
    self.ui:startAttack(attackers)
end

-- move to ui?
function Battle:showEnemyDialogue()
    self.state_vars["enemy_dialogue_bubbles"] = {}

    local active_enemies = self:getActiveEnemies()

    -- move this to another function
    for _,enemy in ipairs(active_enemies) do
        enemy.current_target = enemy:getTarget()
    end
    local cutscene_args = {self.encounter:getDialogueCutscene()}
    if #cutscene_args > 0 then
        self:startCutscene(unpack(cutscene_args)):after(function()
            self:setState("DIALOGUEEND")
        end)
    else
        local any_dialogue = false
        for _,enemy in ipairs(active_enemies) do
            local dialogue = enemy:getDialogue()
            if dialogue then
                any_dialogue = true
                local bubble = enemy:spawnSpeechBubble(dialogue)
                table.insert(self.state_vars["enemy_dialogue_bubbles"], bubble)
            end
        end
        if not any_dialogue then
            self:setState("DIALOGUEEND")
        end
    end
end

function Battle:startDefendingActions()
    -- events
    for i,_ in ipairs(self.party) do
        local action = self.queued_actions[i]
        if action and action.action_type == "DEFEND" then
            self:startAndProcessAction(action)
        end
    end
end

function Battle:checkVictory()
    if #self:getActiveEnemies() == 0 then
        self:setState("VICTORY")
        return true
    end
    return false
end

function Battle:handleVictory()
    --events

    self.current_selecting_index = 0
    self:hideTensionBar()

    self:resetParty()
    self:playVictoryAnimations()

    self.money = self:calculateVictoryMoney(self.money)
    self.xp = self:calculateVictoryXP(self.xp)

    self:checkLevelUp()
    if not self.encounter.no_end_message then
        self:showWinText()
    else
        self:setState("TRANSITIONOUT")
    end
end

function Battle:playVictoryAnimations()
    for _,battler in ipairs(self.party) do
        battler:setAnimation("battle/victory")
    end
end

function Battle:calculateVictoryMoney(money)
    -- if self.dojo then return 0 end

    money = money + (math.floor(((Game:getTension() * 2.5) / 10)) * Game.chapter)

    for _,battler in ipairs(self.party) do
        for _,equipment in ipairs(battler.chara:getEquipment()) do
            self.money = math.floor(equipment:applyMoneyBonus(self.money) or self.money)
        end
    end
    
    money = math.floor(money)
    money = self.encounter:getVictoryMoney(money) or money

    -- Game:addMoney
    Game.money = Game.money + money
    if (Game.money < 0) then
        Game.money = 0
    end

    return money
end

function Battle:calculateVictoryXP(xp)
    return self.encounter:getVictoryXP(xp) or xp
end

function Battle:checkLevelUp()
    if self.used_violence and Game:getConfig("growStronger") then
        Game:levelUp()
    end
end

function Battle:showWinText()
    local win_text = "* You won!\n* Got " .. self.xp .. " EXP and " .. self.money .. " "..Game:getConfig("darkCurrencyShort").."."
    -- if self.dojo then win_text = "* You won the battle!" end

    if self.used_violence and Game:getConfig("growStronger") then
        local stronger_member = "You"

        for _,battler in ipairs(self.party) do
            if battler.chara.id == Game:getConfig("growStrongerChara") then
                stronger = battler.chara:getName()
            end
        end

        win_text = "* You won!\n* Got " .. self.money .. " "..Game:getConfig("darkCurrencyShort")..".\n* "..stronger_member.." became stronger."
        Assets.playSound("dtrans_lw", 0.7, 2)
    end

    win_text = self.encounter:getVictoryText(win_text, self.money, self.xp) or win_text

    self:showText(win_text, function()
        self:setState("TRANSITIONOUT")
        return true
    end)
end

-- Substates

function Battle:setSubState(state, reason)
    local old = self.substate
    self.substate = state
    self.substate_reason = reason
    self:onSubStateChange(old, self.substate)
end

function Battle:onSubStateChange(old, new)
    if old == "ACT" and new ~= "ACT" then
        for _,battler in ipairs(self.party) do
            if battler.sprite.anim == "battle/act" then
                battler:setAnimation("battle/act_end")
            end
        end
    end
end

-- Actions

--- Getters

function Battle:getCurrentAction()
    return self.current_actions[self.current_action_index]
end

function Battle:getActionBy(battler, ignore_current)
    for i, party in ipairs(self.party) do
        if party == battler then
            local action = self.queued_actions[i]
            if action then
                return action
            end
            break
        end
    end

    if ignore_current then return end

    for _,action in ipairs(self.current_actions) do
        local ibattler = self:getPartyBattler(action.party_index)
        if ibattler == battler then
            return action
        end
    end
end

function Battle:getBattlersWithActionType(action_type, ignore_queued, ignore_current)
    if ignore_queued and ignore_current then return end

    local battlers = {}

    if not ignore_queued then
        for _,action in ipairs(self.queued_actions) do
            if action.action_type == action_type then
                table.insert(battlers, self:getPartyBattler(action.party_index))
            end
        end
    end

    if not ignore_current then
        for _,action in ipairs(self.current_action) do
            if action.action_type == action_type then
                table.insert(battlers, self:getPartyBattler(action.party_index))
            end
        end
    end

    return battlers
end

--- Push

function Battle:pushAction(action_type, target, data, party_index, extra)
    party_index = party_index or self.current_selecting_index
    local battler = self.party[party_index]

    if not battler:isActive() then return end

    local current_state = self.state

    self:commitActionFor(battler, action_type, target, data, extra)

    if self.current_selecting_index == party_index then
        if current_state == self.state then
            self:nextParty()
        elseif self.cutscene then

        end
    end
end

--- Commit

-- was commitAction
function Battle:commitActionFor(battler, action_type, target, data, extra)
    if not battler:isActive() then return end

    data = data or {}
    extra = extra or {}

    local used_tp = 0
    if data.tp then
        local tension = Game:getTension()
        local max_tension = Game:getMaxTension()
        used_tp = Utils.clamp(-data.tp, -tension, max_tension - tension)
    end

    local party_index = self:getPartyIndex(battler)

    if data.party then
        for _,member in ipairs(data.party) do
            local index = self:getPartyIndex(battler)

            if index ~= party_index then
                local action = self.queued_actions[index]
                if action then
                    if action.cancellable == false then return end
                    local parent_action = self.queued_actions[action.initiator_index]
                    if parent_action.cancellable == false then return end
                end
            end
        end
    end

    self:commitAction(Utils.merge({
        ["party_index"] = party_index,
        ["action_type"] = action_type:upper(),
        ["target"]      = target,
        ["data"]        = data.data,
        ["name"]        = data.name,
        ["tp"]          = used_tp,
        ["party"]       = data.party,
        ["cancellable"] = data.cancellable
    }, extra))

    if data.party then
        for _,ibattler in ipairs(data.party) do
            local index = self:getPartyIndex(ibattler)

            if index ~= party_index then
                local action = self.queued_actions[index]
                if action then
                    if action then
                        if action.initiator_index then
                            self:removeActionFor(action.initiator_index)
                        else
                            self:removeActionFor(index)
                        end
                    end
                end

                self:commitAction(Utils.merge({
                    ["party_index"]          = index,
                    ["action_type"]          = "OVERRIDE",
                    ["override_action_type"] = action_type:upper(),
                    ["name"]                 = data.name,
                    ["target"]               = target,
                    ["data"]                 = data.data,
                    ["initiator_index"]      = party_index,
                    ["cancellable"]          = data.cancellable,
                }, extra))
            end
        end
    end
end

-- was commitSingleAction
function Battle:commitAction(action)
    local battler = self.party[action.party_index]
    battler.__action = action

    self.queued_actions[action.party_index] = action

    -- event

    local anim = action.action_type:lower()
    if action.action_type == "ITEM" and action.data then
        local result = action.data:onBattleSelect(battler, action.target)
        if result ~= false then
            if action.tp then
                if action.tp > 0 then
                    Game:giveTension(action.tp)
                elseif action.tp < 0 then
                    Game:removeTension(-action.tp)
                end
            end

            local storage, index = Game.inventory:getItemIndex(action.data)
            action.item_storage = storage
            action.item_index = index
            if action.data:hasResultItem() then
                local result_item = action.data:createResultItem()
                Game.inventory:setItem(storage, index, result_item)
                action.result_item = result_item
            else
                Game.inventory:removeItem(action.data)
            end
            action.consumed = true
        else
            action.consumed = false
        end

        action.icon = anim
        if not action.data.instant then
            battler:setAnimation("battle/" .. anim .. "_ready")
        end
    elseif action.action_type == "SPELL" and action.data then
        local result = action.data:onSelect(battler, action.target)
        if result ~= false then
            if action.tp then
                if action.tp > 0 then
                    Game:giveTension(action.tp)
                elseif action.tp < 0 then
                    Game:removeTension(-action.tp)
                end
            end
            battler:setAnimation("battle/" .. anim .. "_ready")
            action.icon = anim
        end
    elseif action.action_type == "OVERRIDE" and action.override_action_type then
        anim = action.override_action_type:lower()
        action.icon = anim
        battler:setAnimation("battle/" .. anim .. "_ready")
    else
        if action.tp then
            if action.tp > 0 then
                Game:giveTension(action.tp)
            elseif action.tp < 0 then
                Game:removeTension(-action.tp)
            end
        end

        battler:setAnimation("battle/" .. anim .. "_ready")
        action.icon = anim

        if action.action_type == "OVERRIDE" and action.override_action_type then
            anim = action.override_action_type:lower()
        end
    end
end

--- Remove

-- was removeAction
function Battle:removeActionFor(battler)
    battler = self:getPartyIndex(battler)
    local action = self.queued_actions[battler]

    if action then
        self:removeAction(action)
    end
end

-- was removeSingleAction
function Battle:removeAction(action)
    local battler = self.party[action.party_index]

    -- event

    battler:resetSprite()

    if action.tp then
        if action.tp < 0 then
            Game:giveTension(-action.tp)
        elseif action.tp > 0 then
            Game:removeTension(action.tp)
        end
    end

    if action.action_type == "ITEM" and action.data then
        if action.item_index and action.consumed then
            if action.result_item then
                Game.inventory:setItem(action.item_storage, action.item_index, action.data)
            else
                Game.inventory:addItemTo(action.item_storage, action.item_index, action.data)
            end
        end
        action.data:onBattleDeselect(battler, action.target)
    elseif action.action == "SPELL" and action.data then
        action.data:onDeselect(battler, action.target)
    end

    battler.__action = nil
    self.queued_actions[action.party_index] = nil
end

--- Start

function Battle:startProcessingActions()
    --self.has_acted = false
    -- event

    self.current_selecting_index = 0

    if not self.encounter:onActionsStart() then
        self:setState("ACTIONS")
    end
end

--- Process

function Battle:tryProcessingNextAction()
    if self.state == "ACTIONS" and not self.currently_processing_action then
        if #self.current_actions == 0 then
            self:processQueuedActions()
        else
            self:processCurrentActions()
        end
    end
end

function Battle:processQueuedActions()
    -- this is dumb
--[[     if self.state ~= "ACTIONS" then
        self:setState("ACTIONS", "DONTPROCESS")
    end ]]

    self.current_action_index = 1
    local order = {"ACT", {"SPELL", "ITEM", "SPARE"}}
    -- event

    -- overrides go last since they do nothing
    table.insert(order, "OVERRIDE")

    for _,action_group in ipairs(order) do
        if self:startActionGroup(action_group) then
            self:tryProcessingNextAction()
            return
        end
    end

    -- maybe move this?
    self:setState("ATTACKING")
end

function Battle:processCurrentActions()
    while self.current_action_index <= #self.current_actions do
        local action = self:getCurrentAction()
        if not self:isActionDone(action) then
            self.currently_processing_action = action
            if self:processAction(action) then
                self:finishAction(action)
            end
            return
        end
        self.current_action_index = self.current_action_index + 1
    end
end

function Battle:startActionGroup(group)
    if type(group) == "string" then
        local found = false
        for i, battler in ipairs(self.party) do
            local action = self.queued_actions[i]
            if action and action.action_type == group then
                found = true
                self:startAction(action)
            end
        end
        for _,action in ipairs(self.current_actions) do
            self.queued_actions[action.party_index] = nil
        end
        return found
    elseif type(group) == "table" then
        for i, battler in ipairs(self.party) do
            local action = self.queued_actions[i]
            if action and Utils.containsValue(group, action.action_type) then
                self.queued_actions[i] = nil
                self:startAction(action)
                return true
            end
        end
    end
end

function Battle:startAction(action)
    local battler = self.party[action.party_index]
    local target = action.target

    table.insert(self.current_actions, action)

    if self.state == "ACTIONS" then
        self:setSubState(action.action_type)
    end

    --event

    if action.action_type == "ACT" then
        target:onACTStart(battler, action.name)
    end
end

function Battle:processAction(action)
    local battler = self.party[action.party_index]
    local member = battler.chara
    local target = action.target

    local next_target = self:retargetEnemy()
    if not next_target then
        return true
    end

    if target and target.done_state then
        target = next_target
        action.target = next_target
    end

    -- events

    local type = action.action_type

    if type == "ATTACK" or action.action_type == "AUTOATTACK" then
        return self:processAttackAction(battler, member, target, action)
    elseif type == "ACT" then
        return self:processACTAction(battler, member, target, action)
    elseif type == "SPELL" then
        return self:processSpellAction(battler, member, target, action)
    elseif type == "ITEM" then
        return self:processItemAction(battler, member, target, action)
    elseif type == "SPARE" then
        return self:processSpareAction(battler, member, target, action)
    elseif type == "DEFEND" then
        return self:processDefendAction(battler, member, target, action)
    elseif type == "OVERRIDE" then
        return self:processOverrideAction(battler, member, target, action)
    else
        Kristal.Console:warn("Couldn't process battle action: " .. tostring(type))
    end
end

function Battle:startAndProcessAction(action)
    self:startAction(action)
    self:processAction(action)
end

function Battle:processAttackAction(battler, member, target, action)
    local sound = Assets.stopAndPlaySound(member:getAttackSound() or "laz_c")
    sound:setPitch(member:getAttackPitch() or 1)

    self.actions_done_timer = 1.2

    -- isn't this 160 for an autoattack in dr?
    local crit = action.points == 150 and action.action ~= "AUTOATTACK"
    if crit then
        -- this gets quieter with certain sounds somehow?
        Assets.stopAndPlaySound("criticalswing")

        for i = 1, 3 do
            local sx, sy = battler:getRelativePos(battler.width, 0)
            local sparkle = Sprite("effects/criticalswing/sparkle", sx + Utils.random(50), sy + 30 + Utils.random(30))
            sparkle:play(4/30, true)
            sparkle:setScale(2)
            sparkle.layer = BATTLE_LAYERS["above_battlers"]
            sparkle.physics.speed_x = Utils.random(2, 6)
            sparkle.physics.friction = -0.25
            sparkle:fadeOutSpeedAndRemove()
            self:addChild(sparkle)
        end
    end

    battler:setAnimation("battle/attack", function()
        action.icon = nil

        if action.target and action.target.done_state then
            target = self:retargetEnemy()
            action.target = target
            if not target then
                self.cancel_attack = true
                self:finishAction(action)
                return
            end
        end

        local damage = Utils.round(target:getAttackDamage(action.damage or 0, battler, action.points or 0))
        damage = math.max(0, damage)

        if damage > 0 then
            target:giveAttackTension(battler, action.points or 0)
            target:createAttackSprite(battler, action.points or 0, crit)
            target:playDamageSound()
            target:hurt(damage, battler)

            member:onAttackHit(target, damage)
        else
            target:hurt(0, battler, nil, nil, nil, action.points ~= 0)
        end

        self:finishAction(action)

        Utils.removeFromTable(self.normal_attackers, battler)
        Utils.removeFromTable(self.auto_attackers, battler)

        if not self:retargetEnemy() then
            self.cancel_attack = true
        elseif #self.normal_attackers == 0 and #self.auto_attackers > 0 then
            local next_attacker = self.auto_attackers[1]

            local next_action = self:getActionBy(next_attacker, true)
            if next_action then
                self:beginAction(next_action)
                self:processAction(next_action)
            end
        end
    end)

    return false
end

function Battle:processACTAction(battler, member, target, action)
    local self_short = false
    self.short_actions = {}
    for _,iaction in ipairs(self.current_actions) do
        if iaction.action == "ACT" then
            local ibattler = self.party[iaction.party_index]
            local itarget = iaction.target

            if itarget then
                local act = itarget and itarget:getAct(iaction.name)

                if (act and act.short) or (itarget:getXAction(ibattler) == iaction.name and itarget:isXActionShort(ibattler)) then
                    table.insert(self.short_actions, iaction)
                    if ibattler == battler then
                        self_short = true
                    end
                end
            end
        end
    end

    if self_short and #self.short_actions > 1 then
        local short_text = {}
        for _,iaction in ipairs(self.short_actions) do
            local ibattler = self.party[iaction.party_index]
            local itarget = iaction.target

            local act_text = itarget:onShortACT(ibattler, iaction.name)
            if act_text then
                table.insert(short_text, act_text)
            end
        end

        self:showShortACTText(short_text)
    else
        local text = target:onACT(battler, action.name)
        if text then
            self:showACTText(text)
        end
    end

    return false
end

function Battle:processSpellAction(battler, member, target, action)
    self:clearUIEncounterText()
    action.data:onStart(battler, target)
    return false
end

function Battle:processItemAction(battler, member, target, action)
    local item = action.data
    if item.instant then
        self:finishAction(action)
    else
        local text = item:getBattleText(battler, target)
        if text then
            self:showText(text)
        end
        battler:setAnimation("battle/item", function()
            local result = item:onBattleUse(battler, target)
            if result or result == nil then
                self:finishAction(action)
            end
        end)
    end
    return false
end

function Battle:processSpareAction(battler, member, target, action)
    local worked = target:canSpare()

    battler:setAnimation("battle/spare", function()
        target:onMercy(battler)
        if not worked then
            target:mercyFlash()
        end
        self:finishAction(action)
    end)

    local text = target:getSpareText(battler, worked)
    if text then
        self:showText(text)
    end

    return false
end

function Battle:processDefendAction(battler, member, target, action)
    battler:setAnimation("battle/defend")
    battler.defending = true
    return false
end

function Battle:processOverrideAction(battler, member, target, action)
    return true
end

function Battle:hasQueuedAction(battler)
    battler = self:getPartyIndex(battler)
    return self.queued_actions[battler] ~= nil
end

--- Finish

function Battle:finishAction(action, keep_animation)
    action = action or self:getCurrentAction()

    local battler = self.party[action.party_index]
    battler.__action = nil

    self.finished_actions[action] = true

    if self.currently_processing_action == action then
        self.currently_processing_action = nil
    end

    local all_processed = self:areAllCurrentActionsDone()

    if all_processed then
        for _,iaction in ipairs(Utils.copy(self.current_actions)) do
            local ibattler = self.party[iaction.party_index]

            local party_index = 1
            local callback = function()
                party_index = party_index - 1
                if party_index == 0 then
                    Utils.removeFromTable(self.current_actions, iaction)
                    self:tryProcessingNextAction()
                end
            end

            if iaction.party then
                for _,party in ipairs(iaction.party) do
                    local jbattler = self.party[self:getPartyIndex(party)]

                    if jbattler ~= ibattler then
                        party_index = party_index + 1

                        local dont_end = false
                        if keep_animation then
                            if Utils.containsValue(keep_animation, party) then
                                dont_end = true
                            end
                        end

                        if not dont_end then
                            self:finishActionAnimation(jbattler, iaction, callback)
                        else
                            callback()
                        end
                    end
                end
            end

            local dont_end = false
            if keep_animation then
                if Utils.containsValue(keep_animation, ibattler.chara.id) then
                    dont_end = true
                end
            end

            if not dont_end then
                self:finishActionAnimation(ibattler, iaction, callback)
            else
                callback()
            end

            if iaction.action_type == "DEFEND" then
                ibattler.defending = false
            end

            -- event
        end
    else
        self:tryProcessingNextAction()
    end
end

function Battle:finishActionBy(battler)
    for _,action in ipairs(self.current_actions) do
        local ibattler = self.party[action.party_index]
        if ibattler == battler then
            self:finishAction(action)
        end
    end
end

function Battle:finishAllActions()
    for _,action in ipairs(self.current_actions) do
        self:finishAction(action)
    end
end

function Battle:markActionAsFinished()

end

function Battle:finishActionAnimation(battler, action, callback)
    local _callback = callback
    callback = function()
        action.icon = nil
        local box = self:getPartyBattlerActionBox(battler)
        box:resetHeadIcon()
        if _callback then
            _callback()
        end
    end
    -- event
    if action.action_type ~= "ATTACK" and action.action_type ~= "AUTOATTACK" then
        if battler.sprite.anim == "battle/"..action.action_type:lower() then
            if not battler:setAnimation("battle/"..action.action_type:lower().."_end", callback) then
                battler:resetSprite()
            end
        else
            battler:resetSprite()
            if callback then
                callback()
            end
        end
    else
        callback()
    end
end

function Battle:isActionDone(action)
    for _,action in ipairs(self.current_actions) do
        if self.finished_actions[action] then
            return true
        end
    end
end

function Battle:areAllCurrentActionsDone()
    for _,action in ipairs(self.current_actions) do
        if not self.finished_actions[action] then
            return false
        end
    end
    return true
end

function Battle:resetActions()
    self:finishAllActions()
    self.queued_actions = {}
    self.current_actions = {}
    self.finished_actions = {}
end

function Battle:resetAttackers()
    if #self.attackers > 0 then
        for _,battler in ipairs(self.attackers) do
            local action = self:getActionBy(battler)
            if action then
                action.icon = nil
            end

            if not battler:setAnimation("battle/attack_end") then
                battler:resetSprite()
            end
        end
        self.attackers = {}
        self.normal_attackers = {}
        self.auto_attackers = {}
        if self.ui.attacking then
            self.ui:endAttack()
        end
    end
end

-- Text

function Battle:showText(text, after)
    local after_state = self.state
    self:setUIEncounterText(text, function()
        self:clearUIEncounterText()
        if type(after) == "string" then
            after_state = after
        elseif type(after) == "function" and after() then
            return
        end
        self:setState(after_state)
    end)
    self.ui.encounter_text:setAdvance(true)

    self:setState("TEXT")
end

function Battle:showACTText(text, dont_finish_action)
    self:showText(text, function()
        if not dont_finish_action then
            self:finishAction()
        end
--[[         if self.should_finish_action then
            self:finishAction(self.on_finish_action, self.on_finish_keep_animation)
            self.on_finish_action = nil
            self.on_finish_keep_animation = nil
            self.should_finish_action = false
        end ]]
        self:setState("ACTIONS", "TEXT")
        return true
    end)
end

--[[ function Battle:showShortACTText(text)
    self:setState("SHORTACTTEXT")
    self:clearUIEncounterText()

    self.battle_ui.short_act_text_1:setText(text[1] or "")
    self.battle_ui.short_act_text_2:setText(text[2] or "")
    self.battle_ui.short_act_text_3:setText(text[3] or "")
end ]]

function Battle:showInfoText(text)
    self:setUIEncounterText(text or "")
end

-- Targeting

function Battle:randomTargetOld()
    -- This is "scr_randomtarget_old".
    local none_targetable = true
    for _,battler in ipairs(self.party) do
        if battler:canTarget() then
            none_targetable = false
            break
        end
    end

    if none_targetable then
        return "ALL"
    end

    -- Pick random party member
    local target = nil
    while not target do
        local party = Utils.pick(self.party)
        if party:canTarget() then
            target = party
        end
    end

    target.should_darken = false
    target.darken_timer = 0
    target.targeted = true
    return target
end

function Battle:randomTarget()
    -- This is "scr_randomtarget".
    local target = self:randomTargetOld()

    if (not Game:getConfig("targetSystem")) and (target ~= "ALL") then
        for _,battler in ipairs(self.party) do
            if battler:canTarget() then
                battler.targeted = true
            end
        end
        return "ANY"
    end

    return target
end

function Battle:targetAll()
    for _,battler in ipairs(self.party) do
        if battler:canTarget() then
            battler.targeted = true
        end
    end
    return "ALL"
end

function Battle:targetAny()
    for _,battler in ipairs(self.party) do
        if battler:canTarget() then
            battler.targeted = true
        end
    end
    return "ANY"
end

function Battle:target(target)
    if type(target) == "number" then
        target = self.party[target]
    end

    if target and target:canTarget() then
        target.targeted = true
        return target
    end

    return self:targetAny()
end

function Battle:getPartyFromTarget(target)
    if type(target) == "number" then
        return {self.party[target]}
    elseif isClass(target) then
        return {target}
    elseif type(target) == "string" then
        if target == "ANY" then
            return {Utils.pick(self.party)}
        elseif target == "ALL" then
            return Utils.copy(self.party)
        else
            for _,battler in ipairs(self.party) do
                if battler.chara.id == string.lower(target) then
                    return {battler}
                end
            end
        end
    end
end

-- splitma, probably
function Battle:hurt(amount, exact, target)
    target = target or "ANY"

    if type(target) == "number" then
        target = self.party[target]
    end

    if isClass(target) and target:includes(PartyBattler) then
        if (not target) or (target.chara:getHealth() <= 0) then -- Why doesn't this look at :canTarget()? Weird.
            target = self:randomTargetOld()
        end
    end

    if target == "ANY" then
        target = self:randomTargetOld()

        local party_average_hp = 1

        for _,battler in ipairs(self.party) do
            if battler.chara:getHealth() ~= battler.chara:getStat("health") then
                party_average_hp = 0
                break
            end
        end

        -- kris gets disadvantage on attack rolls
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end
        if target.chara:getHealth() / target.chara:getStat("health") < (party_average_hp / 2) then
            target = self:randomTargetOld()
        end

        if (target == self.party[1]) and ((target.chara:getHealth() / target.chara:getStat("health")) < 0.35) then
            target = self:randomTargetOld()
        end

        target.should_darken = false
        target.targeted = true
    end

    if isClass(target) and target:includes(PartyBattler) then
        target:hurt(amount, exact)
        return {target}
    end

    if target == "ALL" then
        Assets.playSound("hurt")
        for _,battler in ipairs(self.party) do
            if not battler.is_down then
                battler:hurt(amount, exact, nil, {all = true})
            end
        end

        return Utils.filter(self.party, function(item) return not item.is_down end)
    end
end

-- SOUL

function Battle:spawnSoul(x, y)
    -- event
    x = x or SCREEN_WIDTH/2
    y = y or SCREEN_HEIGHT/2

    local soul_x, soul_y = self:getSoulLocation()
    local color = {self.encounter:getSoulColor()}
    self:addChild(HeartBurst(soul_x, soul_y, color))
    if not self.soul then
        local soul = self.encounter:createSoul(soul_x, soul_y, color)
        soul:transitionTo(x, y)
        soul.target_alpha = soul.alpha
        soul.alpha = 0
        if Game:getConfig("soulInvBetweenWaves") then
            soul.inv_timer = Game.old_soul_inv_timer
        end
        Game.old_soul_inv_timer = 0
        self.soul = soul
        self:addChild(self.soul)
    end

    self:onSpawnSoul()
end

function Battle:onSpawnSoul()
    -- event
    if self.state == "DEFENDINGSTART" or self.state == "DEFENDING" then
        self.soul:onWaveStart()
    end
end

function Battle:getSoulLocation(when_in_battler)
    if self.soul and not when_in_battler then
        return self.soul:getPosition()
    else
        return self.encounter:getSoulSpawnLocation()
    end
end

function Battle:swapSoul(new_soul)
    local old_soul = self.soul
    if old_soul then
        old_soul:remove()
    end
    new_soul:setPosition(old_soul:getPosition())
    new_soul.layer = old_soul.layer
    self.soul = new_soul
    self:addChild(new_soul)
end

function Battle:returnSoul(dont_destroy)
    if dont_destroy == nil then dont_destroy = false end
    local soul_x, soul_y = self:getSoulLocation(true)
    if self.soul then
        Game.old_soul_inv_timer = self.soul.inv_timer
        self.soul:transitionTo(soul_x, soul_y, not dont_destroy)
    end
end

-- Waves

function Battle:initWaves()
    self.finished_waves = false
    self:clearWaves()

    local waves
    if self.state_vars["wave_override"] then
        local enemy_found = false
        for i, enemy in ipairs(self.enemies) do
            if Utils.containsValue(enemy.waves, self.state_vars["wave_override"]) then
                enemy.selected_wave = self.state_vars["wave_override"]
                enemy_found = true
            end
        end
        if not enemy_found then
            self.enemies[love.math.random(1, #self.enemies)].selected_wave = self.state_vars["wave_override"]
        end
    else
        waves = self.encounter:getNextWaves()
    end

    waves = self:setWaves(waves)

    -- literally the worst part of the battle script
    local soul_x, soul_y, soul_offset_x, soul_offset_y
    local arena_x, arena_y, arena_w, arena_h, arena_shape
    local arena_rotation = 0
    local has_arena = true
    local spawn_soul = true
    for _,wave in ipairs(waves) do
        soul_x, soul_y = (wave.soul_start_x or soul_x), (wave.soul_start_y or soul_y)
        soul_offset_x, soul_offset_y = (wave.soul_offset_x or soul_offset_x), (wave.soul_offset_y or soul_offset_y)
        arena_x, arena_y = (wave.arena_x or arena_x), (wave.arena_y or arena_y)
        arena_w = wave.arena_width and math.max(wave.arena_width, arena_w or 0) or arena_w
        arena_h = wave.arena_height and math.max(wave.arena_height, arena_h or 0) or arena_h
        arena_rotation = wave.arena_rotation or arena_rotation
        if wave.arena_shape then
            arena_shape = wave.arena_shape
        end
        if not wave.has_arena then
            has_arena = false
        end
        if not wave.spawn_soul then
            spawn_soul = false
        end
    end

    local center_x, center_y
    if has_arena then
        if not arena_shape then
            arena_w, arena_h = arena_w or 142, arena_h or 142 -- default size variable somewhere?
            arena_shape = {{0, 0}, {arena_w, 0}, {arena_w, arena_h}, {0, arena_h}}
        end

        local arena = self:createArena(arena_x or SCREEN_WIDTH / 2, arena_y or (SCREEN_HEIGHT - 155) / 2 + 10, arena_shape, arena_rotation)
        center_x, center_y = arena:getCenter()
    else
        center_x, center_y = SCREEN_WIDTH / 2, (SCREEN_HEIGHT - 155) / 2 + 10
    end

    if spawn_soul then
        soul_x = soul_x or (soul_offset_x and center_x + soul_offset_x)
        soul_y = soul_y or (soul_offset_y and center_y + soul_offset_y)
        self:spawnSoul(soul_x or center_x, soul_y or center_y)
    end

    for _,wave in ipairs(waves) do
        if wave:onArenaEnter() then
            wave.active = true
        end
    end
end

function Battle:setWaves(waves, allow_duplicates) -- ACTUALLY USE THIS
    local added_waves = {}
    for _,wave in ipairs(waves) do
        local exists = (type(wave) == "string" and added_waves[wave]) or (isClass(wave) and added_waves[wave.id])
        if allow_duplicates or not exists then
            if type(wave) == "string" then
                wave = Registry.createWave(wave)
            end
            wave.encounter = self.encounter
            self:addChild(wave)
            table.insert(self.waves, wave)
            added_waves[wave.id] = true

            wave.active = false
        end
    end

    return self.waves
end

function Battle:updateWaves()
    self.wave_timer = self.wave_timer + DT

    local all_done = true
    for _,wave in ipairs(self.waves) do
        if not wave.finished then
            if wave.time >= 0 and self.wave_timer >= wave.time then
                wave.finished = true
            else
                all_done = false
            end
        end
        if not wave:canEnd() then
            all_done = false
        end
    end

    if all_done and not self.finished_waves then
        if not self.encounter:onWavesDone() then
            self.finished_waves = true
            self:setState("DEFENDINGEND", "WAVEENDED")
        end
    end
end

function Battle:clearWaves(force)
    for _,wave in ipairs(self.waves) do
        if force or not wave:onEnd(false) then
            wave:clear()
            wave:remove()
        end
    end
    self.waves = {}
end

-- Arena

function Battle:createArena(x, y, shape, rotation)
    local arena = Arena(x, y, shape)
    arena.rotation = rotation or 0
    arena.layer = BATTLE_LAYERS["arena"]
    self.arena = arena
    self:addChild(arena)
    return self.arena
end

function Battle:shouldRemoveArena()
    -- event
    local remove_states = {
        "DEFENDINGEND", "TRANSITIONOUT", "ACTIONSELECT", "VICTORY",
        "INTRO", "ACTIONS", "ENEMYSELECT", "PARTYSELECT",
        "MENUSELECT", "ATTACKING"
    }
    return Utils.containsValue(remove_states, self.state)
end

function Battle:removeArena(dont_return_soul)
    if self.soul and not dont_return_soul then
        self:returnSoul()
    end
    if self.arena then
        self.arena:remove()
        self.arena = nil
    end
end

-- Cutscenes

function Battle:inCutscene()
    return self.cutscene and not self.cutscene.ended
end

function Battle:startCutscene(group, id, ...)
    if self.cutscene then
        local cutscene_name = ""
        if type(group) == "string" then
            cutscene_name = group
            if type(id) == "string" then
                cutscene_name = group.."."..id
            end
        elseif type(group) == "function" then
            cutscene_name = "<function>"
        end
        error("Attempt to start a cutscene "..cutscene_name.." while already in cutscene "..self.cutscene.id)
    end
    self.cutscene = BattleCutscene(group, id, ...)
    return self.cutscene
end

function Battle:startActCutscene(group, id, dont_finish)
    local action = self:getCurrentAction()
    local cutscene
    if type(id) ~= "string" then
        dont_finish = id
        cutscene = self:startCutscene(group, self.party[action.character_id], action.target)
    else
        cutscene = self:startCutscene(group, id, self.party[action.character_id], action.target)
    end
    return cutscene:after(function()
        if not dont_finish then
            self:finishAction(action)
        end
        self:setState("ACTIONS", "CUTSCENE")
    end)
end

-- Update

-- section for this
function Battle:advanceEnemyDialogue()
    local all_done = true
    local bubbles_to_remove = {}
    for _,bubble in ipairs(self.state_vars["enemy_dialogue_bubbles"]) do
        if bubble:isTyping() then
            all_done = false
            break
        end
    end
    if all_done then
        self.state_vars["enemy_dialogue_timer"] = 90
        self.state_vars["use_textbox_timer"] = true
        for _,bubble in ipairs(self.state_vars["enemy_dialogue_bubbles"]) do
            bubble:advance()
            if not bubble:isDone() then
                all_done = false
            else
                table.insert(bubbles_to_remove, bubble)
            end
        end
    end
    for _,bubble in ipairs(bubbles_to_remove) do
        Utils.removeFromTable(self.state_vars["enemy_dialogue_bubbles"], bubble)
        bubble:remove()
    end
    if all_done then
        self:setState("DIALOGUEEND")
    end
end

function Battle:update()
    self:cleanupEnemies()

    -- beforebattleupdate kristal event/encounter callback
    
    local state = self.state
    if state == "TRANSITION" then
        self:updateTransition()
    elseif state == "INTRO" then
        self:updateIntro()
    elseif state == "ACTIONSDONE" then
        self.actions_done_timer = Utils.approach(self.actions_done_timer, 0, DT) -- DTMULT?
        local any_hurt = false
        for _,enemy in ipairs(self.enemies) do
            if enemy.hurt_timer > 0 then
                any_hurt = true
                break
            end
        end
        if self.actions_done_timer == 0 and not any_hurt then
            self:resetAttackers()
            self.ui:finishAttack()
            if not self.encounter:onActionsEnd() then
                self:setState("ENEMYDIALOGUE")
            end
        end
    elseif state == "ENEMYDIALOGUE" then
        self.state_vars["enemy_dialogue_timer"] = self.state_vars["enemy_dialogue_timer"] - DTMULT
        if self.state_vars["enemy_dialogue_timer"] <= 0 and (self.state_vars["use_textbox_timer"] or true) then
            self:advanceEnemyDialogue()
        else
            local all_done = true
            for _,textbox in ipairs(self.state_vars["enemy_dialogue_bubbles"]) do
                if not textbox:isDone() then
                    all_done = false
                    break
                end
            end
            if all_done then
                self:setState("DIALOGUEEND")
            end
        end
    elseif state == "DEFENDINGSTART" then
        self.state_vars["defending_start_timer"] = self.state_vars["defending_start_timer"] + DTMULT
        if self.state_vars["defending_start_timer"] >= 15 then
            self:setState("DEFENDING")
        end
    elseif state == "DEFENDING" then
        self:updateDefending()
    elseif state == "TRANSITIONOUT" then
        self:updateTransitionOut()
    end

    self:updateEncounter()

    super.update(self)
end

function Battle:forceDefeatEnemy(index)
    self.enemies[index]:onDefeat()
end

function Battle:cleanupEnemies()
    if #self.enemies_to_remove > 0 then
        for i, enemy in ipairs(self.enemies_to_remove) do
            Utils.removeFromTable(self.enemies, enemy)
            self.enemy_list[i] = false
        end
        self.enemies_to_remove = {}
    end
end

function Battle:updateTransition()
    self:updatePartyTransition()
    self:updateEnemyTransition()
    self.state_vars["transition_timer"] = self.state_vars["transition_timer"] + DTMULT

    if self.state_vars["transition_timer"] >= 10 then
        self:setState("INTRO", nil)
    end
end

function Battle:updateIntro()
    self.state_vars["intro_timer"] = self.state_vars["intro_timer"] + DTMULT
    if self.state_vars["intro_timer"] >= 15 then -- TODO: find out why this is 15 instead of 13
        for _,battler in ipairs(self.party) do
            battler:setAnimation("battle/idle")
        end
        self:nextTurn()
        self:setState("ACTIONSELECT", "INTRO")
        self:showUIElements()
    end
end

function Battle:updatePartyTransition()
    self:updatePartyTransitionAfterImages()

    for i, battler in ipairs(self.party) do
        local x, y = unpack(self.world_positions.party[i])
        local target_x, target_y = unpack(self.transition_targets.party[i])

        battler.x = Utils.lerp(x, target_x, self.state_vars["transition_timer"] / 10)
        battler.y = Utils.lerp(y, target_y, self.state_vars["transition_timer"] / 10)
    end
end

function Battle:updatePartyTransitionAfterImages()
    while self.state_vars["afterimage_count"] < math.floor(self.state_vars["transition_timer"]) do
        for i, battler in ipairs(self.party) do
            local x, y = unpack(self.world_positions.party[i])
            local target_x, target_y = unpack(self.transition_targets.party[i])

            local battler_x = battler.x
            local battler_y = battler.y

            local afterimage_count = self.state_vars["afterimage_count"]
            battler.x = Utils.lerp(x, target_x, (afterimage_count + 1) / 10)
            battler.y = Utils.lerp(y, target_y, (afterimage_count + 1) / 10)

            local afterimage = AfterImage(battler, 0.5)
            self:addChild(afterimage)

            battler.x = battler_x
            battler.y = battler_y
        end
        self.state_vars["afterimage_count"] = self.state_vars["afterimage_count"] + 1
    end
end

function Battle:updateEnemyTransition()
    for _,enemy in ipairs(self.enemies) do
        local x, y = unpack(self.world_positions.enemies[enemy])
        local target_x, target_y = unpack(self.transition_targets.enemies[enemy])
        
        enemy.x = Utils.lerp(x, target_x, self.state_vars["transition_timer"] / 10)
        enemy.y = Utils.lerp(y, target_y, self.state_vars["transition_timer"] / 10)
    end
end

function Battle:updateDefending()
    self:updateWaves()
end

function Battle:updateEncounter()
    if self.state ~= "TRANSITIONOUT" then
        self.encounter:update()
    end
end

function Battle:updateTransitionOut()
    self.state_vars["transition_out_timer"] = self.state_vars["transition_out_timer"] - DTMULT

    if self.state_vars["transition_out_timer"] <= 0 then
        self.encounter:onReturnToWorld(Utils.copy(self.world_characters.enemies))
        self:returnToWorld()
        return
    end

    self:updatePartyTransitionOut()
    self:updateEnemyTransitionOut()
end

function Battle:updatePartyTransitionOut()
    for i, battler in ipairs(self.party) do
        -- make this use their current positions when the out transition starts
        local x, y = unpack(self.world_positions.party[i])
        local init_x, init_y = unpack(self.transition_targets.party[i])

        battler.x = Utils.lerp(x, init_x, self.state_vars["transition_out_timer"] / 10)
        battler.y = Utils.lerp(y, init_y, self.state_vars["transition_out_timer"] / 10)
    end
end

function Battle:updateEnemyTransitionOut()
    for _,enemy in ipairs(self.all_enemies) do
        local world_chara = self.world_characters.enemies[enemy]
        local x, y = unpack(self.world_positions.enemies[enemy])
        local init_x, init_y = unpack(self.transition_targets.enemies[enemy])

        if world_chara and not enemy.exit_on_defeat and world_chara.parent then
            enemy.x = Utils.lerp(x, init_x, self.state_vars["transition_out_timer"] / 10)
            enemy.y = Utils.lerp(y, init_y, self.state_vars["transition_out_timer"] / 10)
        else
            -- ehhhhhhhh maybe just do it once when the state is set
            local fade_fx = enemy:getFX("battle_end")
            if not fade_fx then
                fade_fx = enemy:addFX(AlphaFX(1), "battle_end")
            end
            fade_fx.alpha = self.state_vars["transition_out_timer"] / 10
        end
    end
end

function Battle:checkGameOver()
    -- use proper functions
    for _,battler in ipairs(self.party) do
        if not battler.is_down then
            return
        end
    end
    self.music:stop()
    if self.state == "DEFENDING" then
        for _,wave in ipairs(self.waves) do
            wave:onEnd(true)
        end
    end
    if self.encounter:onGameOver() then
        return
    end
    Game:gameOver(self:getSoulLocation())
end

function Battle:returnToWorld()
    -- events

    if not Game:getConfig("keepTensionAfterBattle") then
        Game:setTension(0)
    end
    -- redo this maybe? add a counter?
    self.encounter:setFlag("done", true)
    if self.used_violence then
        self.encounter:setFlag("violenced", true)
    end
    self.transition_timer = 0
    for _,battler in ipairs(self.party) do
        if self.world_characters.party[battler.chara.id] then
            self.world_characters.party[battler.chara.id].visible = true
        end
    end
    for _,enemy in ipairs(self.all_enemies) do
        local world_chara = self.world_characters.enemies[enemy]
        if world_chara then
            world_chara.visible = true
        end
        if not enemy.exit_on_defeat and world_chara and world_chara.parent then
            if world_chara.onReturnFromBattle then
                world_chara:onReturnFromBattle(self.encounter, enemy)
            end
        end
    end
    if self.encounter_context and self.encounter_context:includes(ChaserEnemy) then
        for _,enemy in ipairs(self.encounter_context:getGroupedEnemies(true)) do
            enemy:onEncounterEnd(enemy == self.encounter_context, self.encounter)
        end
    end
    self.music:stop()
    if self.resume_world_music then
        Game.world.music:resume()
    end
    self:remove()
    self.encounter.defeated_enemies = self.defeated_enemies
    Game.battle = nil
    Game.state = "OVERWORLD"
end

-- Draw

function Battle:debugPrintOutline(string, x, y, color)
    color = color or COLORS.white
    Draw.setColor(COLORS.black)
    Draw.print(string, x - 1, y)
    Draw.print(string, x + 1, y)
    Draw.print(string, x, y - 1)
    Draw.print(string, x, y + 1)

    Draw.setColor(color)
    Draw.print(string, x, y)
end

function Battle:drawDebug()
    local font = Assets.getFont("main", 16)
    Draw.setFont(font)

    Draw.setColor(COLORS.white)
    self:debugPrintOutline("State: "        ..  self.state, 4, 0)
    self:debugPrintOutline("State Reason: " .. (self.state_reason or "NONE"), 4, 16)
    self:debugPrintOutline("Substate: "     ..  self.substate, 4, 32)
end

function Battle:draw()
    super.draw(self)

    if DEBUG_RENDER then
        self:drawDebug()
    end
end

-- Input

function Battle:handleDebugInput(key)
    if Kristal.Config["debug"] and Input.ctrl() then
        if key == "h" then
            for _,battler in ipairs(self.party) do
                battler:heal(math.huge)
            end
        end
        if key == "y" then
            Input.clear(nil, true)
            self:setState("VICTORY")
        end
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        end
        if self.state == "DEFENDING" and key == "f" then
            self.encounter:onWavesDone()
        end
        if self.soul and self.soul.visible and key == "j" then
            local x, y = self:getSoulLocation()
            self.soul:shatter(6)
            
            -- Prevents a crash related to not having a soul in some waves
            -- WHAT THE FUCK DO YOU MEAN????
            self:spawnSoul(x, y)
            for _,heartburst in ipairs(Game.stage:getObjects(HeartBurst)) do
                heartburst:remove()
            end
            self.soul.visible = false
            self.soul.collidable = false
        end
        if key == "b" then
            for _,battler in ipairs(self.party) do
                battler:hurt(math.huge)
            end
        end
        if key == "k" then
            Game:setTension(Game:getMaxTension() * 2, true)
        end
        if key == "n" then
            NOCLIP = not NOCLIP
        end
    end
end

function Battle:handleUIInput(key)
    if self.ui then self.ui:onKeyPressed(key) end
end

function Battle:onKeyPressed(key)
    self:handleDebugInput(key)
    self:handleUIInput(key)
end

-- Etc.

function Battle:onRemove(parent)
    super.onRemove(self, parent)
    -- don't do this
    self.music:remove()
end

function Battle:hasCutscene()
    return self.cutscene and not self.cutscene.ended
end

function Battle:checkSolidCollision(collider)
    if NOCLIP then return false end
    Object.startCache()
    if self.arena then
        if self.arena:collidesWith(collider) then
            Object.endCache()
            return true, self.arena
        end
    end
    for _,solid in ipairs(Game.stage:getObjects(Solid)) do
        if solid:collidesWith(collider) then
            Object.endCache()
            return true, solid
        end
    end
    Object.endCache()
    return false
end

function Battle:retargetEnemy()
    for _,enemy in ipairs(self.enemies) do
        if not enemy.done_state then
            return enemy
        end
    end
end

function Battle:isWorldHidden()
    return self.state ~= "TRANSITION" and self.state ~= "TRANSITIONOUT" and
           (self.encounter.background or self.encounter.hide_world)
end

function Battle:sortChildren()
    -- event?????
    table.stable_sort(self.children, function(a, b)
        return a.layer < b.layer or (a.layer == b.layer and (a:includes(Battler) and b:includes(Battler)) and a.y < b.y)
    end)
end

function Battle:updateChildren()
    if self.update_child_list then
        self:updateChildList()
        self.update_child_list = false
    end
    for _,draw_fx in ipairs(self.draw_fx) do
        draw_fx:update()
    end
    for _,child in ipairs(self.children) do
        -- only update if Game.battle is still a reference to this instance
        if child.active and child.parent == self and Game.battle == self then
            child:fullUpdate()
        end
    end
end

function Battle:canDeepCopy()
    return false
end

return Battle