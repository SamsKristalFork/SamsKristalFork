local Scripts = {}
local self = Scripts

Scripts.paths = {}

function Scripts.registerPath(id, path)
    Scripts.paths[id] = path
end

function Scripts.registerBasePaths()
    Scripts.registerPath("globals",          "globals")
    Scripts.registerPath("objects",          "objects")
    Scripts.registerPath("drawfx",           "drawfx")

    Scripts.registerPath("actors",           "data/actors")
    Scripts.registerPath("party_members",    "data/party")
    Scripts.registerPath("items",            "data/items")
    Scripts.registerPath("spells",           "data/spells")
    Scripts.registerPath("recruits",         "data/recruits")

    Scripts.registerPath("maps",             "world/maps")
    Scripts.registerPath("tilesets",         "world/tilesets")
    Scripts.registerPath("events",           "world/events")
    Scripts.registerPath("event_scripts",    "world/scripts")
    Scripts.registerPath("world_bullets",    "world/bullets")
    Scripts.registerPath("world_cutscenes",  "world/cutscenes")

    Scripts.registerPath("encounters",       "battle/encounters")
    Scripts.registerPath("enemies",          "battle/enemies")
    Scripts.registerPath("waves",            "battle/waves")
    Scripts.registerPath("bullets",          "battle/bullets")
    Scripts.registerPath("battle_cutscenes", "battle/cutscenes")

    Scripts.registerPath("legend_cutscenes", "legends/")

    --onpathsregistered event
end

function Scripts.initialize()
    self.registerBasePaths()
end

function Scripts.execChunk(id, path)
    local worked, chunk = pcall(love.filesystem.load, self.paths[id].."/"..path..".lua")
    if not worked then return false, "Couldn't load " .. path end

    local worked, exec = pcall(chunk)
    if not worked then return false, "Couldn't call " .. tostring(path) end

    return exec
end

function Scripts.exists(id, path)
    return love.filesystem.getInfo(self.paths[id].."/"..path..".lua")
end

function Scripts.load(id, path)
    local script = Scripts.execChunk(id, path)
    --script.id = script.id or path
    return script
end

return Scripts