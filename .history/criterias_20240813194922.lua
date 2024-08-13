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
    local player = playerModule:GetPlayerById(id)
    if not player and id >= -1 then
        print("WARNING: Invalid id in matchWorld criteria", id)
    end
    if id < -1 then -- Console
        return true
    end
    return (connection.player and player and connection.player.world == player.world) and true or false
end

module.notSelf = function(connection, id)
    return connection.player and connection.player.id ~= id
end

return module