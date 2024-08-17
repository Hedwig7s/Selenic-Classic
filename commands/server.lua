---@class CommandServer: Command

local server = require("../server")
local config = require("../config")

---Executes the command
---@param player Player
---@param _ table<string>
local function execute(player, _)
    local message = [[
&9Server Information:
&aServer Name: &f%s
&bServer Software: &9%s
&eServer Version: &a%s
&5Server Source: &d%s
&cAuthor: &a%s]]
    player:SendMessage(message:format(config:getValue("server.serverName"), server.info.Software, server.info.Version, server.info.Source, server.info.Author))
    return true
end

return {
    NAME = "server",
    DESCRIPTION = "Lists server information",
    USAGE = "/server", 
    ALIASES = {"serverinfo", "info", "i"},
    execute = execute
}