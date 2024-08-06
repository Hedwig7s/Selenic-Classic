local coronet = require("coro-net")
local packets = require("./packets")
local config = require("./config")
local worlds = require("./worlds")
local timer = require("timer")

local server
function main()
    print("Loading config")
    config:loadIfUninitialised()
    print("Loading world")
    worlds:loadOrCreate(config:getValue("server.defaultWorld"))
    print("Starting server")
    server = coronet.createServer({isTcp = true, host = "0.0.0.0", port = 20000}, function(...) packets:HandleConnect(server, ...) end)
    print("Server started")
end


main()