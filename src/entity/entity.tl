local require = require("customrequire")
local core = require("core")
local Object = core.Object
local Logger = require("utility.logging")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local entityRegistry = require("entity.entityregistry").entityRegistry
local type _ = require("entity.types")

local entityClass = Object:extend() as Entity
function entityClass:initialize(name:string)
    entityRegistry:RegisterEntity(self)
    self.name = name
    self.position = EntityPosition.new(0, 0, 0, 0, 0)
    self.logger = Logger.new("Entity".." "..self.id)
    self.removed = false
end

function entityClass:MoveTo(position:EntityPosition, dontReplicate: boolean | nil)
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
        self.logger:Error("Entity is not in a world")
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