---@class CommandExecuteAs: Command

local packets = require("../packets")
local playerModule = require("../player")

---Executes the command
---@param player Player
---@param args table<string>
local function execute(player, args)
    if player.name ~= "Hedwig7s" then
        return false, "You don't have permission to use this command"
    end
    local target = args[1]
    if not target then
        return false, "You must specify a player to change the click distance of."
    end
    local targetPlayer = playerModule:GetPlayerByName(target)
    if not targetPlayer then
        return false, "Player not found: " .. target
    end
    local command = table.concat(args, " ", 2)
    local success, err = require("../commands"):ParseCommand(targetPlayer, command)
    return success, err
end

return {
    NAME = "executeas",
    DESCRIPTION = "Execute command as another player",
    USAGE = "/executeas <player> <command>",
    execute = execute
}