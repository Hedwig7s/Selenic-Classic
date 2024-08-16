---@class CommandGoto: Command

local worlds = require("../worlds")

---Executes the command
---@param player Player
---@param args table<string>
local function execute(player, args)
    local name = args[1]
    if not name then
        return false, "You must specify a world to go to."
    end
    if not worlds.loadedWorlds[name] then
        return false, "World does not exist or isn't loaded."
    end
    player:SendMessage("&aGoing to world: " .. name)
    player:LoadWorld(worlds.loadedWorlds[name])
end

return {
    NAME = "goto",
    DESCRIPTION = "Sends you to world.",
    USAGE = "/goto <world>",
    execute = execute,
}