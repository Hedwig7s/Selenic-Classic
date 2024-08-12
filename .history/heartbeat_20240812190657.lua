local module = {}

local http = require("http")
local config = require("./config")
local server = require("./server")

function heartbeat()
    local url = config:getValue("server.heartbeatUrl")
    if not url then
        return
    end
    url = url .. "?port=" .. config:getValue("server.port")
    http.get(url, function(_, _, res)
        if res.statusCode ~= 200 then
            print("Failed to send heartbeat")
        end
    end)
end



return module