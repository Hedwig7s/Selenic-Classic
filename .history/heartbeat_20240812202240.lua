local module = {}

local http = require("http")
local timer = require("timer")
local querystring = require("querystring")
local config = require("./config")
local server = require("./server")
local playerModule = require("./player")

local firstHeartbeat = true

---Sends heartbeat to heartbeat url
function heartbeat()
    local url = config:getValue("server.heartbeatURL")
    if not url then
        return
    end

    local params = {
        name = querystring.urlencode(config:getValue("server.name")),
        port = config:getValue("server.port"),
        users = #playerModule:GetPlayers(),
        max = config:getValue("server.maxPlayers"),
        public = config:getValue("server.public") and "true" or "false",
        salt = server.info.Salt,
        software = querystring.urlencode(string.format("%s %s", server.info.Software, server.info.Version)),
        web = "false"
    }
    print(require("inspect")(params))
    local query = {}
    local i = 1
    for k, v in pairs(params) do
        local prefix = i == 1 and "?" or "&"
        query[i] = prefix .. k .. "=" .. v
        i = i + 1
    end

    url = url .. table.concat(query)

    local function request(url, callback)
        local body = ""
        http.get(url, function(res)
            res:on('data', function(chunk)
                body = body .. chunk
            end)
            res:on("end", function()
                if res.statusCode >= 300 and res.statusCode < 400 and res.headers.location then
                    -- Handle redirect
                    local newUrl = res.headers.location
                    request(newUrl, callback)
                else
                    callback(res, body)
                end
            end)
        end)
    end

    request(url, function(res, body)
        if res.statusCode ~= 200 then
            print("Failed to send heartbeat")
            print(body)
        end
        if firstHeartbeat then
            firstHeartbeat = false
            print("Heartbeat URL: " .. body)
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
    running = false
end

return module
