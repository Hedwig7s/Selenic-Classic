---@class CommandPlayers: Command

local playerModule = require("../player")

---Executes the command
---@param player Player
---@param _ table<string>
local function execute(player, _)
    local message = "&bOnline players: "
    local players = playerModule:GetPlayers()
    local data = {}
    for i,v in pairs(players) do
        if not data[v.world.name] then
            data[v.world.name] = {}
        end
        table.insert(data[v.world.name], v.name)
    end
    for world,players in pairs(data) do
        message = message.."&bIn world "..world..":&f"..table.concat(world, ", ").."\n"
    end
    message = message:gsub("\n$", "")
    player:SendMessage(message)
    return true
end

return {
    NAME = "players",
    DESCRIPTION = "Shows all online players",
    USAGE = "/players",
    execute = execute
}