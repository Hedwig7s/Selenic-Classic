local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")
local playerRegistry = require("entity.playerregistry")
local colorcodes = require("utility.colorcodes")

local _ = require("messaging.criterias")

MessagingBase = {}

local messagingBase = class("MessagingBase")

function messagingBase:initialize() end

function messagingBase:ProcessMessage(target, message, criteria, data)
	message = colorcodes(message)
	message = message:gsub("%%(.)", function(char)
		return "&" .. char
	end)

	if not ((criteria and criteria(target, message, data)) or not criteria) then
		return nil
	end
	return message
end

function messagingBase:Message(target, message, criteria, data)
	message = self:ProcessMessage(target, message, criteria, data)
	if message then
		self:RawSend(target, message)
	end
end

function messagingBase:Broadcast(message, criteria, data)
	for _, player in ipairs(playerRegistry:GetEntities()) do
		local player = player
		self:Message(player, message, criteria, data)
		self.logger:Info("Message: " .. message)
	end
end

return messagingBase
