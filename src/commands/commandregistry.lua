local require = require("customrequire")
local _ = require("entity.types")

local class = require("middleclass")

local commandRegistry = class("CommandRegistry")

function commandRegistry:initialize()
	self.commands = {}
end

function commandRegistry:Register(command)
	self.commands[command.meta.name] = command
	for _, alias in ipairs(command.meta.aliases) do
		self.commands[alias] = command
	end
end

function commandRegistry:Unregister(command)
	self.commands[command.meta.name] = nil
	for _, alias in ipairs(command.meta.aliases) do
		self.commands[alias] = nil
	end
end

function commandRegistry:Get(name)
	return self.commands[name]
end

return commandRegistry
