local require = require("customrequire")

local core = require("core")
local Object = core.Object
local Logger = require("utility.logging")
local timer = require("timer")
local http = require("http")
local querystring = require("querystring")
local internalInfo = require("data.internalinfo")
local serverConfig = require("data.config.serverconfig")
local playerRegistry = require("entity.playerregistry")

global record Heartbeat
    extend: function(self:Heartbeat): Heartbeat
    initialize: function(self:Heartbeat)
    new: function(self:Heartbeat): Heartbeat
    start: function(self:Heartbeat)
    stop: function(self:Heartbeat)
    interval: integer
    running: boolean
    logger: Logger
    firstHeartbeat: boolean
    intervalObject: timer.Timer
    sendHeartbeat: function(self:Heartbeat)
end

local heartbeat = Object:extend() as Heartbeat

function heartbeat:initialize()
    local self = self as Heartbeat
    self.logger = Logger.new("Heartbeat")
    self.running = false
    self.firstHeartbeat = true
    self.interval = serverConfig:get("heartbeat.interval") as integer
end

function heartbeat:sendHeartbeat()
    local url = serverConfig:get("heartbeat.url") as string
    local params = {
        name = querystring.urlencode(serverConfig:get("server.serverName") as string),
        port = serverConfig:get("server.port"),
        users = #playerRegistry:GetEntities(),
        max = serverConfig:get("server.maxPlayers"),
        public = serverConfig:get("heartbeat.public") and "true" or "false",
        salt = internalInfo.Salt,
        software = querystring.urlencode(string.format("%s %s", internalInfo.Software, internalInfo.Version)),
        web = "false"
    }
    local query = {}
    local i = 1
    for k, v in pairs(params as {string:any}) do
        local prefix = i == 1 and "?" or "&"
        query[i] = prefix .. k .. "=" .. tostring(v)
        i = i + 1
    end

    url = url .. table.concat(query) 

    local function request(url:string, callback: function(res:http.response, body:string))
        local body = ""
        http.get(url, function(res:http.response)
            res:on('data', function(chunk:string)
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

    request(url, function(res:http.response, body:string)
        if res.statusCode ~= 200 then
            self.logger:Error("Failed to send heartbeat\n"..body, true)
        end
        if self.firstHeartbeat then
            self.firstHeartbeat = false
            self.logger:Info("Server URL: " .. body)
        end
    end)
end

function heartbeat:start()
    local self = self as Heartbeat
    if self.running then
        self.logger:Warn("Attempted to start heartbeat when it was already running")
        return
    end
    self.running = true
    self.logger:Info("Starting heartbeat")
    self:sendHeartbeat()
    self.intervalObject = timer.setInterval(self.interval, function()
        self:sendHeartbeat()
    end)
end

function heartbeat:stop()
    local self = self as Heartbeat
    if not self.running then
        self.logger:Warn("Attempted to stop heartbeat when it was not running")
        return
    end
    self.running = false
    self.logger:Info("Stopping heartbeat")
    timer.clearInterval(self.intervalObject)
end

return heartbeat