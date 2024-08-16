local module = {}

local toml = require("toml")
local fs = require("fs")
local util = require("./util")

local initialised = false

local defaultConfig = {
    server = {
        host = "0.0.0.0",
        port = 25565,
        maxPlayers = 20,
        serverName = "Selenic Server",
        motd = "Welcome!",
        verifyNames = true,
        localBypassVerification = false,
        public = true,
        heartbeat = true,
        heartbeatURL = "http://www.classicube.net/server/heartbeat/",
        defaultWorld = "world",
        defaultWorlds = {"world"},
        useRelativeMovement = false,
        perWorldChat = false,
    },
    protocol = {
        enabled = {
            ["1"] = true,
            ["3"] = true,
            ["4"] = true,
            ["5"] = true,
            ["6"] = true,
            ["7"] = true,
            CPE = true,
        },
    }
}

local config = {}

function module:loadConfig()
    local data 
    pcall(function()
        data = fs.readFileSync("./config.toml")
    end)
    data = (data and #data>0 and data)
    local success
    success, config = pcall(toml.decode, data)
    if not success or not data or #data < 1 then
        print("Error parsing config file, using default config")
        config = util.deepCopy(defaultConfig)
    end
    config = util.merge(config, defaultConfig)
    initialised = true
    if config.server.maxPlayers > 126 then
        config.server.maxPlayers = 126
        print("Max players cannot exceed 126, setting to 126")
    end
    module:saveConfig()
end

function module:saveConfig()
    local file = fs.openSync("config.toml", "w")
    fs.writeSync(file,nil,toml.encode(config))
    fs.closeSync(file)
end

function module:loadIfUninitialised()
    if not initialised then
        self:loadConfig()
    end
end
local function getTable(t, str)
    local split = util.split(str, ".")
    if not string.match(str, ".") then
        return t, str
    end
    local current = t
    local currentKey = ""
    for i = 1, #split-1 do
        if not current[split[i]] then
            current[split[i]] = {}
        end
        current = current[split[i]]
        currentKey = split[i+1]
    end
    return current, currentKey
end
function module:setValue(key, value) 
    local t, key = getTable(config, key)
    if not initialised then
        error("Config not initialised")
    end
    t[key] = value
end

function module:getValue(key)
    local t, key = getTable(config, key)
    if not initialised then
        error("Config not initialised")
    end
    return t[key]
end
return module