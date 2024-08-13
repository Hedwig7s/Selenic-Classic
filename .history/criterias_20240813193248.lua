---@alias criteria fun(connection: Connection, id:number):boolean

local lazyLoaded = {}

local function lazyLoad(moduleName)
    if not lazyLoaded[moduleName] then
        lazyLoaded[moduleName] = require(moduleName)
    end
    return lazyLoaded[moduleName]
end
local module = {}

module.matchWorld = function(connection, id)
    local playerModule = lazyLoad("./player")
    local player = playerModule.getPlayer(id)
    return connection.player and player and connection.player.world == player.world
end

module.notSelf = function(connection, id)
    return connection.player and connection.player.id ~= id
end

return module