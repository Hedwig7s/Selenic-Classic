local require = require("customrequire")
local class = require("utility.class")
local logging = require("utility.logging")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local type _ = require("entity.types")

local entities = {}

local entityClass = class("Entity", {
    singleton = false,
    constructor = function(self:Instance)
        local self = self as Entity
        for i=1, 255 do
            if not entities[i] then
                self.id = i
                break
            end
        end
        self.position = EntityPosition.new(0, 0, 0, 0, 0)
        self.logger = logging.new(self.__class__.__name__.." "..self.id)
        entities[self.id] = self
    end,
    values = {
        MoveTo = function(self:Entity, position:EntityPosition)
            self.position = position
        end,
        Spawn = function(self:Entity)
            self.logger:Error("Not implemented")
        end,
        SetBlock = function(self:Entity, position:Vector3, block:Block)
            local world = self.world
            if world is nil then
                self.logger:Error("Entity is not in a world")
                return
            end
            world:SetBlock(position, block)
        end,
        LoadWorld = function(self:Entity, world:World)
            self.world = world
        end
    }
})

return entityClass