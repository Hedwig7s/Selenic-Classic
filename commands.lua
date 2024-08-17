---@class CommandsModule
local module = {}

local util = require("./util")
local fs = require("fs")
local loader = require("loader")

local commands = {}
local aliases = {}

function module:loadCommands(reload)

    for _, file in ipairs(fs.readdirSync("./commands/")) do
        if file:sub(-4) == ".lua" then
            file = file:sub(1, -5)
            if reload then
                loader.unload("commands/" .. file)
            end
            local command = loader.load("commands/" .. file)
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
end
module:loadCommands(false)
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
    local success, result, err = pcall(commandModule.execute,player, args)
    if not success then
        print("Error executing command: " .. result)
        return false, "An error occurred while executing the command."
    end
    return result, err
end

return module