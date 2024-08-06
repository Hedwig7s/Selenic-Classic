local coronet = require("coro-net")
local packets = require("./packets")
local config = require("./config")
local worlds = require("./worlds")
local timer = require("timer")

local server
function main()
    config:loadIfUninitialised()
    worlds:loadOrCreate(config:getValue("server.defaultWorld"))
    local autoSave = timer.setInterval(60000, function()
        for _, world in pairs(worlds.loadedWorlds) do
            world:save()
        end
    end)
    server = coronet.createServer({isTcp = true, host = "0.0.0.0", port = 20000}, function(...) packets:HandleConnect(server, ...) end)
end


main()