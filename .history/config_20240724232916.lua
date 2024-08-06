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
    pcall(function()
        local file = fs.open("config.toml", "r")
        data = fs.read(file)
    end)
    data = data or defaultConfig

end

local function saveConfig()
    fs.write("config.toml", toml.encode(config))
end
loadConfig()
saveConfig()
return module