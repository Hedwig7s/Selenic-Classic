local require = require("customrequire")
local core = require("core")
local Logger = require("utility.logging")
local Object = core.Object
local playerRegistry = require("entity.playerregistry")
local colorcodes = require("utility.colorcodes")
local type _ = require("entity.types")
local type _ = require("messaging.criterias")

global record MessagingBase
    initialize: function(self:MessagingBase, name:string)
    new: function(self:MessagingBase, name:string): MessagingBase
    extend: function(self:MessagingBase): MessagingBase
    name: string
    logger:Logger
    Broadcast: function(self:MessagingBase, message:string, criteria:MessageCriteria, data:MessageCriteriaData)
    Message: function(self:MessagingBase, target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData)
    ProcessMessage: function(self:MessagingBase, target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData): string|nil 
    RawSend: function(self:MessagingBase, target:Player, message:string)
end

local messagingBase = Object:extend() as MessagingBase

function messagingBase:initialize(name:string)
    local self = self as MessagingBase
    self.name = name
    self.logger = Logger.new(name)
end

function messagingBase:ProcessMessage(target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData): string|nil
    message = colorcodes(message)
    message = message:gsub("%%(.)", function(char:string):string
        return "&" .. char
    end)

    if not ((criteria and criteria(target, message, data)) or not criteria) then
        return nil
    end
    return message
end

function messagingBase:Message(target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData)
    message = self:ProcessMessage(target, message, criteria, data)
    if message then
        self:RawSend(target, message)
    end
end

function messagingBase:Broadcast(message:string, criteria:MessageCriteria, data:MessageCriteriaData)
    for _, player in ipairs(playerRegistry:GetEntities()) do
        local player = player as Player
        self:Message(player, message, criteria, data)
    end
end

return messagingBase