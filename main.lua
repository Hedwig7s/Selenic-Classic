local require = require("customrequire")
local serverClass = require("networking/server")
local serverConfig = require("data/config/serverconfig")
local loggerClass = require("utility.logging")
local logger = loggerClass.new("Main")
local heartbeat = require("networking/heartbeat")
local worldManager = require("data/worlds/worldmanager")
local Vector3 = require("datatypes/vector3")
local timer = require("timer")
local process = require("process").globalProcess()
local uv = require("uv")
local worldsLoaded = false
local server

function onExit()
    logger:Info("Shutting down.")
    if server then
        server:close()
    end
    if worldsLoaded then
        worldManager.saveAll()
    end
    logger:Info("Exiting.")
end

process:on("uncaughtException", function(err)
    logger:Fatal("Uncaught exception: " .. err)
    pcall(onExit)
    os.exit(-1)
end)
process:on("exit", onExit)
uv.signal_start_oneshot(uv.new_signal(),"sigint", function()
    pcall(onExit)
    os.exit(0)
end)

logger:Info("Loading config...")

do
    local success, err = pcall(function()
        serverConfig:loadFromFile()
        loggerClass.globalSettings.DEBUG = serverConfig:get("server.debug")
    end)
    if not success then
        logger:Fatal("Failed to load config: " .. err)
        os.exit(-2)
    end
end

logger:Info("Loading worlds...")

do
    local success, err = pcall(function()
        worldManager:loadOrCreate(serverConfig:get("server.defaultWorld"), "hworld", Vector3.new(512, 128, 512))
        worldsLoaded = true
        timer.setInterval(60000, worldManager.saveAll)
    end)
    if not success then
        logger:Fatal("Failed to load worlds: " .. err)
        os.exit(-3)
    end
end

logger:Info("Starting server...")
do 
    local success, err = pcall(function()
        server = serverClass:new(serverConfig:get("server.host"), serverConfig:get("server.port"))
        server:init()
    end)
    if not success then
        logger:Fatal("Fatal error occured while running server: " .. err)
        os.exit(-4)
    end
end

if serverConfig:get("heartbeat.enabled") then
    logger:Info("Starting heartbeat...")
    local success, err = pcall(function()
        local hb = heartbeat:new()
        hb:start()
    end)
    if not success then
        logger:Error("Error occured while starting heartbeat: " .. err)
    end
end