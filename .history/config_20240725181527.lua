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
        serverName = "Lunatic Server",
        motd = "Welcome!",
        levelName = "default",
        verifyNames = true,
        public = true,
        heartbeatURL = "https://classicube.net/server/heartbeat"
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
        currentKey = split[i]
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