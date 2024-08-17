---@class CommandReload: Command

local lazyLoaded = {}
local function lazyLoad(module)
    if lazyLoaded[module]==nil then
        lazyLoaded[module] = require(module) or false
    end
    return lazyLoaded[module]
end

---Executes the command
---@param player Player
---@param _ table<string>
local function execute(player, _)
    if player.name ~= "Hedwig7s" then
        return false, "You don't have permission to reload commands."
    end
    local commands = lazyLoad("../commands")
    commands:loadCommands(true)
    player:SendMessage("&aCommands reloaded!")
    return true
end

return {
    NAME = "reload",
    DESCRIPTION = "Reloads all commands",
    USAGE = "/reload",
    execute = execute
}