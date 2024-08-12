local module = {}

local http = require("http")
local timer = require("timer")
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
        .. "&public=" .. (config:getValue("server.public") and "true" or "false")
        .. "&salt=" .. server.info.Salt
        .. "&software=" .. server.info.Software.." "..server.info.Version
        .. "&web=false"

    http.get(url, function(_, _, res)
        if res.statusCode ~= 200 then
            print("Failed to send heartbeat")
        end
    end)
end

local running = false
local heartbeatRoutine

local function createRoutine()
    if heartbeatRoutine and coroutine.status(heartbeatRoutine) ~= "dead" then
        return
    end
    heartbeatRoutine = coroutine.create(function()
        while running do
            heartbeat()
            timer.sleep(10000)
        end
    end)
end

function module:Start()
    running = true
    createRoutine()
    coroutine.resume(heartbeatRoutine)
end

function module:Stop()
    running = true
end

return module