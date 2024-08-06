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
        data = fs.readFile("config.toml")
    end)
    data = data or defaultConfig

end

local function saveConfig()
    local file = fs.open("config.toml", "w")
    file.write(toml.encode(config))
end
loadConfig()
saveConfig()
return module