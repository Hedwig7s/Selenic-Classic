local require = require("customrequire")
local type _ = require("entity.types")
local type Commands = require("commands.types")
local type Command = Commands.Command
local type CommandRegistry = Commands.CommandRegistry
local class = require("middleclass")

local commandRegistry = class("CommandRegistry") as CommandRegistry

function commandRegistry:initialize()
    self.commands = {}
end

function commandRegistry:Register(command:Command)
    self.commands[command.meta.name] = command
    for _, alias in ipairs(command.meta.aliases) do
        self.commands[alias] = command
    end
end

function commandRegistry:Unregister(command:Command)
    self.commands[command.meta.name] = nil
    for _, alias in ipairs(command.meta.aliases) do
        self.commands[alias] = nil
    end
end

function commandRegistry:Get(name:string): Command|nil
    return self.commands[name]
end

return commandRegistry