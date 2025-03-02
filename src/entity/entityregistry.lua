local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")

EntityRegistry = {}

local registryClass = class("EntityRegistry")
function registryClass:initialize(name, supers)
	local self = self
	self.entities = setmetatable({}, {
		__len = function(t)
			local count = 0
			for _, v in ipairs(t) do
				if v and not v.removed then
					count = count + 1
				end
			end
			return count
		end,
	})
	self.name = name
	self.supers = supers
	self.logger = Logger.new(name .. "Registry")
end

local function checkExists(registry, entity, id)
	local ent = registry:GetEntity(id)
	if ent and ent == entity then
		return true
	end
	if not ent then
		return true
	end
	return false
end

function registryClass:RegisterEntity(entity, id)
	if not (type(entity) == "table") then
		error(self.logger:FormatErr("Attempted to register non-entity"))
		return
	end
	local function checkSupers(i)
		local supers = self.supers
		if supers == nil then
			return true
		end
		for _, v in ipairs(supers) do
			if not checkExists(v, entity, i) then
				return false
			elseif not v.entities[i] then
				v:RegisterEntity(entity, i)
			end
		end
		return true
	end
	if not (id == nil) then
		if checkExists(self, entity, id) and checkSupers(id) then
			entity.id = id
			self.entities[id] = entity
			return
		else
			error(self.logger:FormatErr("Failed to register entity. ID already in use"))
			return
		end
	end
	for i = 1, 255 do
		if checkExists(self, entity, i) and checkSupers(i) then
			entity.id = i
			self.entities[i] = entity
			break
		end
	end
	if not entity.id then
		error(self.logger:FormatErr("Failed to register entity. Out of ids"))
		return
	end
end
function registryClass:GetEntity(id)
	return self.entities[id]
end
function registryClass:GetEntityByName(name)
	for _, v in ipairs(self.entities) do
		if v.name == name then
			return v
		end
	end
	return nil
end
function registryClass:UnregisterEntity(entity)
	if type(entity) == "number" then
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
		for _, v in ipairs(self.supers) do
			v:UnregisterEntity(entity)
		end
	end
end
function registryClass:GetEntities()
	return self.entities
end

return { entityRegistry = registryClass:new("Entity"), registryClass = registryClass }
