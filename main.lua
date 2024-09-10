local require = require("customrequire")
local serverClass = require("networking/server")
local serverConfig = require("data/config/serverconfig")
local loggerClass = require("utility.logging")
local logger = loggerClass.new("Main")
local heartbeat = require("networking/heartbeat")
local worldModule = require("data/worlds/worlds")
local Vector3 = require("datatypes/vector3")
local timer = require("timer")

logger:Info("Loading config...")

do
    local success, err = pcall(function()
        serverConfig:loadFromFile()
        loggerClass.globalSettings.DEBUG = serverConfig:get("server.debug")
    end)
    if not success then
        logger:Fatal("Failed to load config: " .. err)
    end
end

logger:Info("Loading worlds...")

do
    local success, err = pcall(function()
        worldModule:loadOrCreate(serverConfig:get("server.defaultWorld"), "hworld", Vector3.new(512, 128, 512))
        timer.setInterval(20000, worldModule.saveAll)
    end)
    if not success then
        logger:Fatal("Failed to load worlds: " .. err)
    end
end

logger:Info("Starting server...")

do 
    local success, err = pcall(function()
        local server = serverClass:new(serverConfig:get("server.host"), serverConfig:get("server.port"))
        server:init()
    end)
    if not success then
        logger:Fatal("Fatal error occured while running server: " .. err)
    end
end

if serverConfig:get("heartbeat.enabled") then
    logger:Info("Starting heartbeat...")
    local success, err = pcall(function()
        local hb = heartbeat:new()
        hb:start()
    end)
    if not success then
        logger:Error("Fatal error occured while starting heartbeat: " .. err, true)
    end
end