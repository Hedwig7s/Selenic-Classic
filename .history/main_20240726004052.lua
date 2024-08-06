local coronet = require("coro-net")
local packets = require("./packets")
local config = require("./config")


local server
function main()
    config:loadIfUninitialised()
    server = coronet.createServer({isTcp = true, host = "0.0.0.0", port = 20000}, function(...) packets:HandleConnect(server, ...) end)
end

function cleanup()
    print("Cleaning up")
    server:close()
end
local oldExit = os.exit
os.exit = function(...)
    cleanup()
    oldExit(...)
end

main()