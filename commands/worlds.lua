---@class CommandWorlds: Command

local worlds = require("../worlds")
local fs = require("fs")

---Executes the command
---@param player Player
---@param _ table<string>
local function execute(player, _)
    local unloaded = {}
    local loaded = {}
    for _,v in pairs(fs.readdirSync("./worlds")) do
        v = v:gsub(".hworld", "")
        if worlds.loadedWorlds[v] then
            table.insert(loaded, "&a"..v)
        else
            table.insert(unloaded, "&c"..v)
        end
    end
    local message = [[
&bLoaded Worlds: 
%s
&3Unloaded Worlds: 
%s]]
    player:SendMessage(message:format(table.concat(loaded, ", "), table.concat(unloaded, ", ")))
    return true
end

return {
    NAME = "worlds",
    DESCRIPTION = "Lists all worlds.",
    USAGE = "/worlds",
    execute = execute,
    ALIASES = {"worldlist", "listworlds", "listworld", "worldlist", "levels"}
}