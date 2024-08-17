---@class CommandClients: Command

local playerModule = require("../player")

---Executes the command
---@param player Player
---@param _ table<string>
local function execute(player, _)
    local message = "&bClients:\n"
    local players = playerModule:GetPlayers()
    for i,v in pairs(players) do
        message = message.."    &f"..v.name..": "..v.client.."\n"
    end
    message = message:gsub("\n$", "")
    player:SendMessage(message)
    return true
end

return {
    NAME = "clients",
    DESCRIPTION = "Shows clients of all players",
    USAGE = "/clients",
    execute = execute,
    ALIASES = {"pclient"}
}