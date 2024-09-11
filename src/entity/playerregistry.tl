local require = require("customrequire")
local type _ = require("entity.types")
local rd = require("entity.entityregistry")
local entityRegistry, registryClass = rd.entityRegistry, rd.registryClass

return registryClass:new("Player", {entityRegistry}) as EntityRegistry