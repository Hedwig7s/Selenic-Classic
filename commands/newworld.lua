---@class CommandNewWorld: Command

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
        return false, "You must specify a name for the world."
    end
    player:SendMessage("Creating new world with name: " .. name)
    if worlds:loadOrCreate(name) then
        player:SendMessage("World created successfully.")
        return true
    end
    return false, "Failed to create world."
end

return {
    NAME = "newworld",
    DESCRIPTION = "Creates new world with name.",
    USAGE = "/newworld <name>",
    execute = execute,
    ALIASES = {"createworld", "worldcreate", "worldnew"}
}