---@class CommandToggleWorldChat: Command

local config = require("../config")

---Executes the command
---@param player Player
---@param _ table<string>
local function execute(player, _)
    if config:getValue("server.perWorldChat") then
        return false, "Chat must be per-world."
    end
    local perWorldChat = not player.info.perWorldChat
    player.info.perWorldChat = perWorldChat
    player:SendMessage("&aChat is now " .. (perWorldChat and "per-world" or "global") .. ".")
    return true
end

return {
    NAME = "toggleworldchat",
    DESCRIPTION = "Toggles whether chat is per-world or global",
    USAGE = "/toggleworldchat",
    execute = execute,
    ALIASES = { "twc" }
}