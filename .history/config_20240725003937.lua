local module = {}

local toml = require("toml")
local fs = require("fs")

local initialised = false

local defaultConfig = {
    server = {
        host = "0.0.0.0",
        port = 25565,
    }
}
local function deepCopy(t)
    local copy = {}
    for k,v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local config = {}

local function loadConfig()
    local data 
    pcall(function()
        data = fs.readFileSync("./config.toml")
    end)
    data = (data and #data>0 and data)
    local success
    success, config = pcall(toml.decode, data)
    if not success or not data or #data < 1 then
        print("Error parsing config file, using default config")
        config = deepCopy(defaultConfig)
    end
    initialised = true
end

local function saveConfig()
    local file = fs.openSync("config.toml", "w")
    fs.writeSync(file,nil,toml.encode(config))
    fs.closeSync(file)
end

return module