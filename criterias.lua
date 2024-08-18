---@alias criteria fun(connection: Connection, id:number):boolean

local lazyLoaded = {}
local timer = require("timer")


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

module.hasExtension = function(extension)
    return function(connection, id)
        local player = connection.player        
        if not player then
            return false
        end
        if player and player.supportsCPE then
            while not player.identifiedCPE and player.supportsCPE do
                timer.sleep(1)
            end
        end
        return player.CPE[extension] and true or false
    end
end

return module