---@class CommandWhisper: Command

local playerModule = require("../player")

---Executes the command
---@param player Player
---@param args table<string>
local function execute(player, args)
    -- TODO: Add mute
    local target = args[1]
    if not target then
        return false, "Please specify a player"
    end
    local targetPlayer = playerModule:GetPlayerByName(target)
    if not targetPlayer then
        return false, "Player not found"
    end
    local message = table.concat(args, " ", 2)
    if not message or #message:gsub("%s", "") == 0 then
        return false, "Please specify a message"
    end
    message = "&7"..player.name.." -> " .. targetPlayer.name .. ": " .. message
    player:SendMessage(message)
    targetPlayer:SendMessage(message)
    return true
end

return {
    NAME = "whisper",
    DESCRIPTION = "Sends a message in secret to a player",
    USAGE = "/whisper <player> <message>",
    execute = execute,
    ALIASES = { "w", "msg", "tell", "message" }
}