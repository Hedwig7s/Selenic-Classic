local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local entityRegistry = require("entity.entityregistry").entityRegistry
local type Entities = require("entity.types")
local type Entity = Entities.Entity
local type Worlds = require("data.worlds.types")
local type World = Worlds.World

local entityClass = class("Entity") as Entity
function entityClass:initialize(name:string)
    entityRegistry:RegisterEntity(self)
    self.name = name
    self.position = EntityPosition.new(0, 0, 0, 0, 0)
    self.logger = Logger.new("Entity".." "..self.id)
    self.removed = false
end

function entityClass:MoveTo(position:EntityPosition, dontReplicate?: boolean)
    self.position = position
end
function entityClass:Spawn()
    
end
function entityClass:Despawn()
    
end
function entityClass:Remove()
    self:Despawn()
    entityRegistry:UnregisterEntity(self.id)
    self.removed = true
end
function entityClass:SetBlock(position:Vector3, block:Block)
    local world = self.world
    if world is nil then
        error(self.logger:FormatErr("Entity is not in a world"))
        return
    end
    world:SetBlock(position, block)
end
function entityClass:LoadWorld(world:World)
    if self.world then
        self:Despawn()
    end
    self.world = world
end


return entityClass