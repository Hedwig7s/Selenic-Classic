---@class CommandLoadWorld: Command

local worlds = require("../worlds")

---Executes the command
---@param player Player
---@param args table<string>
local function execute(player, args)
    if player.name ~= "Hedwig7s" then -- Temporary until permissions are implemented
        return false, "You do not have permission to use this command."
    end
    local name = args[1]
    if not name then
        return false, "You must specify the world's name."
    end
    player:SendMessage("Loading world with name: " .. name)
    if worlds:load(name) then
        player:SendMessage("World loaded successfully.")
        return true
    end
    return false, "Failed to load world." 
end

return {
    NAME = "loadworld",
    DESCRIPTION = "Creates new world with name.",
    USAGE = "/loadworld <name>",
    execute = execute,
    ALIASES = {"load", "worldload"}
}