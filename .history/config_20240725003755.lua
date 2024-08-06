local module = {}

local toml = require("toml")
local fs = require("fs")

local initialised = false

local defaultConfig = {
    server = {
        host = "0.0.0.0",
        port = 20000,
    }
}

local config = {}

local function loadConfig()
    local data 
    pcall(function()
        data = fs.readFileSync("./config.toml")
    end)
    data = (data and #data>0 and data) or defaultConfig
    print(data)
    local success
    success, config = pcall(toml.decode, data)
    if not success then
        print("Error parsing config file, using default config")
        config = toml.decode(defaultConfig)
    end
    initialised = true
end

local function saveConfig()
    local file = fs.openSync("config.toml", "w")
    fs.writeSync(file,nil,toml.encode(config))
    fs.closeSync(file)
end

return module