local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")
local playerRegistry = require("entity.playerregistry")
local colorcodes = require("utility.colorcodes")
local type Entities = require("entity.types")
local type Player = Entities.Player
local type _ = require("messaging.criterias")

global record MessagingBase
    initialize: function(self:MessagingBase)
    new: function(self:MessagingBase): MessagingBase
    static: table
    isSubclassOf: function(self: MessagingBase, other:class.Class): boolean
    include: function(self: MessagingBase, ...:table): MessagingBase
    subclassed: function(self: MessagingBase, other:class.Class)
    allocate: function(self: MessagingBase): table
    isInstanceOf: function(self: MessagingBase, class: class.Class): boolean
    subclass: function(self:MessagingBase,name:string): MessagingBase
    logger:Logger
    Broadcast: function(self:MessagingBase, message:string, criteria:MessageCriteria, data:MessageCriteriaData)
    Message: function(self:MessagingBase, target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData)
    ProcessMessage: function(self:MessagingBase, target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData): string|nil 
    RawSend: function(self:MessagingBase, target:Player, message:string)
end

local messagingBase = class("MessagingBase") as MessagingBase

function messagingBase:initialize()
    --local self = self as MessagingBase
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