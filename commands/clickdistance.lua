---@class CommandClickDistance: Command

local packets = require("../packets")

---Executes the command
---@param player Player
---@param args table<string>
local function execute(player, args)
    if player.name ~= "Hedwig7s" then
        return false, "You don't have permission to use this command"
    end
    if not player.CPE["ClickDistance"] then
        return false, "This command requires the ClickDistance extension"
    end
    local distance = tonumber(args[1])
    if not distance then
        return false, "Invalid distance"
    end
    player.clickDistance = distance*32
    packets.ExtensionPackets.ClickDistance(player.connection, distance*32)
    player:SendMessage("&eClick distance set to " .. distance)
    return true
end

return {
    NAME = "clickdistance",
    DESCRIPTION = "Changes click distance",
    USAGE = "/clickdistance <distance>",
    execute = execute,
    ALIASES = { "setclickdistance", "reach" }
}