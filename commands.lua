---@class CommandsModule
local module = {}

local util = require("./util")
local fs = require("fs")

local commands = {}
local aliases = {}

for _, file in ipairs(fs.readdirSync("./commands/")) do
    if file:sub(-4) == ".lua" then
        local command = require("./commands/" .. file)
        if command.NAME then
            commands[command.NAME:lower()] = command
            if command.ALIASES then
                for _, alias in ipairs(command.ALIASES) do
                    aliases[alias:lower()] = command
                end
            end
        end
    end
end

module.commands = commands
module.aliases = aliases

---@param str string
---@param player Player
function module:ParseCommand(player, str)
    print(player.name .. " issued command: " .. str)
    local args = util.split(str, " ")
    local command = args[1]
    if not command then
        return false
    end
    table.remove(args, 1)
    local commandModule = commands[command] or aliases[command]
    if not commandModule then
        return false, "Unknown command: " .. command
    end
    -- TODO: Add selectors
    return commandModule.execute(player, args)
end

return module