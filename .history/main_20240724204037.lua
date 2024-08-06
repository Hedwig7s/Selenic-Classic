local coronet = require("coro-net")
local packets = require("packets")


local server
function main()
    server = coronet.createServer({isTcp = true, host = "0.0.0.0", port = 25565}, function(...) packets:HandleConnect(server, ...) end)
    
end
main()