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
    print("Loading world")
    worlds:loadOrCreate(config:getValue("server.defaultWorld"))
    local autoSave = coroutine.wrap(function()
        while true do
            timer.sleep(30000)
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