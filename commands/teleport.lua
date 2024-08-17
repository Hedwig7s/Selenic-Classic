---@class CommandTeleport: Command

local playerModule = require("../player")

local function teleportToPlayer(player, args)
    local to = args[1]
    local from = player.name
    if args[2] then
        if player.name ~= "Hedwig7s" then
            return false, "You don't have permission to teleport other players."
        end
        to = args[2]
        from = args[1]
    end
    if not to then
        return false, "You must specify a player to teleport to."
    end
    local fromPlayer = playerModule:GetPlayerByName(from)
    local toPlayer = playerModule:GetPlayerByName(to)
    if not toPlayer or not fromPlayer then
        return false, "Player not found: " .. not toPlayer and to or from
    end
    player:SendMessage("&aTeleporting "..(args[2] and fromPlayer.name.." " or "").."to " .. toPlayer.name)
    if fromPlayer.world.name ~= toPlayer.world.name then
        fromPlayer:LoadWorld(toPlayer.world)
    end
    fromPlayer:MoveTo(toPlayer.position)
    fromPlayer:SendMessage("&eYou have been teleported to " .. toPlayer.name)
    toPlayer:SendMessage("&e" .. fromPlayer.name .. " has teleported to you")
    return true
end

local function teleportToPosition(player, args)
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])
    if not x or not y or not z then
        return false, "Invalid coordinates."
    end
    player:SendMessage("&aTeleporting to " .. x .. " " .. y .. " " .. z)
    player:MoveTo({x = x, y = y+1, z = z})
    return true
end

---Executes the command
---@param player Player
---@param args table<string>
local function execute(player, args)
    if #args <= 2 then
        return teleportToPlayer(player, args)
    elseif #args >= 3 then
        return teleportToPosition(player, args)
    else
        return false, "Invalid arguments."
    end
end

return {
    NAME = "teleport",
    DESCRIPTION = "Teleport to player or location",
    USAGE = "/teleport <player> [target], /teleport <x> <y> <z>",
    execute = execute,
    ALIASES = {"tp"}
}