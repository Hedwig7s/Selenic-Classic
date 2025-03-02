local require = require("customrequire")
local rd = require("entity.entityregistry")
local entityRegistry, registryClass = rd.entityRegistry, rd.registryClass

return registryClass:new("Player", { entityRegistry })
