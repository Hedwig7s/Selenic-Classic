local require = require("customrequire")
local class = require("utility.class")
local Logger = require("utility.logging")
local type _ = require("entity.types")

global record EntityRegistry
    __class__: BaseClass
    entities: {Entity}
    name: string
    logger: Logger
    supers: {EntityRegistry} | nil
    RegisterEntity: function(self:EntityRegistry, entity:Entity, id:integer|nil)
    UnregisterEntity: function(self:EntityRegistry, entity:Entity | integer)
    GetEntity: function(self:EntityRegistry, id:integer): Entity
    GetEntities: function(self:EntityRegistry): {Entity}
end

local registryClass = class("EntityRegistry", {
    constructor = function(self:Instance, name:string, supers: {EntityRegistry} | nil)
        local self = self as EntityRegistry
        self.entities = {}
        self.name = name
        self.supers = supers
        self.logger = Logger.new(name.."Registry")
    end,
    values = {
        RegisterEntity = function(self:EntityRegistry, entity:Entity, id:integer|nil)
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
                    if v.entities[i] == entity then -- In case of double registration
                        return true
                    elseif v.entities[i] then
                        return false
                    end
                end
                return true
            end
            if not id is nil then
                if not self.entities[id] and checkSupers(id) then
                    entity.id = id
                    self.entities[id] = entity
                    return
                else
                    self.logger:Error("Failed to register entity. ID already in use")
                    return
                end
            end
            for i=1, 1024 do
                if not self.entities[i] and checkSupers(i) then
                    entity.id = i
                    self.entities[i] = entity
                    break
                end
            end
            if not entity.id then
                self.logger:Error("Failed to register entity. Out of ids")
                return
            end
        end,
        GetEntity = function(self:EntityRegistry, id:integer): Entity
            return self.entities[id]
        end,
        UnregisterEntity = function(self:EntityRegistry, entity:Entity | integer)
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
        end,
        GetEntities = function(self:EntityRegistry): {Entity}
            return self.entities
        end
    }
})

return {entityRegistry = registryClass("Entity") as EntityRegistry, registryClass = registryClass}