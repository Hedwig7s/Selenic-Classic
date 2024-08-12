local module = {}

local http = require("http")
local config = require("./config")
local server = require("./server")
local playerModule = require("./player")

---Sends heartbeat to heartbeat url
function heartbeat()
    local url = config:getValue("server.heartbeatUrl")
    if not url then
        return
    end
    url = url 
        .. "?name=" .. config:getValue("server.name")
        .. "?port=" .. config:getValue("server.port")
        .. "&users=" .. #playerModule:GetPlayers()
        .. "&max=" .. config:getValue("server.maxPlayers")
    http.get(url, function(_, _, res)
        if res.statusCode ~= 200 then
            print("Failed to send heartbeat")
        end
    end)
end



return module