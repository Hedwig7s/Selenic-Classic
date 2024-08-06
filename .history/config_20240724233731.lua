local module = {}

local toml = require("toml")
local fs = require("fs")

local initialised = false

local defaultConfig = [[
[server]
port = 20000
host = 0.0.0.0 
]]

local config = {}

local function loadConfig()
    local data 
    local s, e = pcall(function()
        data = fs.readFile("config.toml")
    end)
    print(s,e)
    data = data or defaultConfig

end

local function saveConfig()
    local file = fs.openSync("config.toml", "w")
    fs.writeSync(file,toml.encode(config))
    fs.closeSync(file)
end
loadConfig()
saveConfig()
return module