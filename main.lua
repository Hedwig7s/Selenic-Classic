local uv = require("uv")    
local packets = require("./packets")
local config = require("./config")
local worlds = require("./worlds")
local timer = require("timer")
local heartbeat = require("./heartbeat")

local server
function main()
    print("Loading config")
    config:loadIfUninitialised()
    print("Loading worlds")
    local defaultWorld = config:getValue("server.defaultWorld")
    for _, world in pairs(config:getValue("server.defaultWorlds")) do
        if not (world == defaultWorld and worlds:loadOrCreate(world) or worlds:load(world)) then
            print("WARNING: Failed to load world: " .. world)
        end
    end
    local autoSave = coroutine.wrap(function()
        while true do
            timer.sleep(20000)
            worlds:saveAll()
        end
    end)
    autoSave()
    print("Starting server")
    --server = coronet.createServer({isTcp = true, host = config:getValue("server.host"), port = config:getValue("server.port")}, function(...) packets:HandleConnect(server, ...) end)
    server = uv.new_tcp()
    server:bind(config:getValue("server.host"), config:getValue("server.port"))
    server:listen(128, packets.HandleConnect(server))
    print("Server started")
    if config:getValue("server.heartbeat") then
        print("Starting heartbeat")
        heartbeat:Start()
        print("Heartbeat started")
    end
end


main()