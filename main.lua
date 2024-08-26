local require = require("customrequire")
local serverClass = require("networking/server")
local serverConfig = require("data/config/serverconfig")
local loggerClass = require("logging")
local logger = loggerClass.new("Main")
local worldModule = require("data/worlds/worlds")
local Vector3 = require("datatypes/vector3")
local timer = require("timer")

logger:Info("Loading config...")
serverConfig:loadFromFile()

logger:Info("Loading worlds...")
worldModule.loadOrCreate("world", "hworld", Vector3.new(512, 128, 512))
timer.setInterval(20000, worldModule.saveAll)

logger:Info("Starting server...")

local server = serverClass("0.0.0.0", 25565)
server:init()