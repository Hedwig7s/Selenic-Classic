---@class CommandPing: Command

---Executes the command
---@param player Player
---@param _ table<string>
local function execute(player, _)
    player:SendMessage("Pong!")
    return true
end

return {
    NAME = "ping",
    DESCRIPTION = "Replies with Pong!",
    USAGE = "/ping",
    execute = execute
}