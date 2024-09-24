local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")
local type Entities = require("entity.types")
local type Entity = Entities.Entity

global record EntityRegistry
    initialize: function(self:EntityRegistry, name:string, supers: {EntityRegistry} | nil)
    new: function(self:EntityRegistry, name:string, supers: {EntityRegistry} | nil): EntityRegistry
    extend: function(self:EntityRegistry):  EntityRegistry
    entities: {Entity}
    name: string
    logger: Logger
    supers: {EntityRegistry} | nil
    RegisterEntity: function(self:EntityRegistry, entity:Entity, id:integer|nil)
    UnregisterEntity: function(self:EntityRegistry, entity:Entity | integer)
    GetEntity: function(self:EntityRegistry, id:integer): Entity|nil
    GetEntityByName: function(self:EntityRegistry, name:string): Entity|nil
    GetEntities: function(self:EntityRegistry): {Entity}
end

local registryClass = class("EntityRegistry") as EntityRegistry
function registryClass:initialize(name:string, supers: {EntityRegistry} | nil)
    local self = self as EntityRegistry
    self.entities = setmetatable({}, {
        __len = function(t:{Entity}): integer
            local count = 0
            for _, v in ipairs(t) do
                if v and not v.removed then
                    count = count + 1
                end
            end
            return count
        end
    })
    self.name = name
    self.supers = supers
    self.logger = Logger.new(name.."Registry")
end

local function checkExists(registry:EntityRegistry, entity:Entity, id:integer): boolean
    local ent = registry:GetEntity(id)
    if ent and ent == entity then
        return true
    end
    if not ent then
        return true
    end
    return false
    
end

function registryClass:RegisterEntity(entity:Entity, id:integer|nil)
    if not entity is Entity then
        self.logger:Error("Attempted to register non-entity")
        return
    end
    local function checkSupers(i:integer): boolean
        local supers = self.supers
        if supers is nil then
            return true
        end
        for _, v in ipairs(supers) do
            if not checkExists(v,entity, i) then
                return false
            elseif not v.entities[i] then
                v:RegisterEntity(entity, i)
            end
        end
        return true
    end
    if not id is nil then
        if checkExists(self,entity, id) and checkSupers(id) then
            entity.id = id
            self.entities[id] = entity
            return
        else
            self.logger:Error("Failed to register entity. ID already in use")
            return
        end
    end
    for i=1, 255 do
        if checkExists(self,entity, i) and checkSupers(i) then
            entity.id = i
            self.entities[i] = entity
            break
        end
    end
    if not entity.id then
        self.logger:Error("Failed to register entity. Out of ids")
        return
    end
end
function registryClass:GetEntity(id:integer): Entity | nil
    return self.entities[id]
end
function registryClass:GetEntityByName(name:string): Entity | nil
    for _, v in ipairs(self.entities) do
        if v.name == name then
            return v
        end
    end
    return nil
end 
function registryClass:UnregisterEntity(entity:Entity | integer)
    if entity is integer then
        self.entities[entity] = nil
    else
        for i, v in ipairs(self.entities) do
            if v == entity then
                self.entities[i] = nil
                break
            end
        end
    end
    if self.supers then
        for _, v in ipairs(self.supers as {EntityRegistry}) do
            v:UnregisterEntity(entity)
        end
    end
end
function registryClass:GetEntities(): {Entity}
    return self.entities
end


return {entityRegistry = registryClass:new("Entity") as EntityRegistry, registryClass = registryClass}