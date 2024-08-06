local coronet = require("coro-net")
local packets = require("./packets")
local config = require("./config")
local worlds = require("./worlds")


local server
function main()
    config:loadIfUninitialised()
    worlds:loadOrCreate(config:getValue("server.defaultWorld"))
    server = coronet.createServer({isTcp = true, host = "0.0.0.0", port = 20000}, function(...) packets:HandleConnect(server, ...) end)
end


main()