local module = {}

local toml = require("~/.luarocks/lib/lua/5.1/toml")
local fs = require("fs")

local initialised = false

local defaultConfig = [[
[server]
port = 20000
host = "0.0.0.0" 
]]

local config = {}

local function loadConfig()
    local data 
    pcall(function()
        data = fs.readFileSync("./config.toml")
    end)
    data = (data and #data>0 and data) or defaultConfig
    print(data)
    config = toml.decode(data)
    print(table.concat(config, ","))
    initialised = true
end

local function saveConfig()
    local file = fs.openSync("config.toml", "w")
    fs.writeSync(file,nil,toml.encode(config))
    fs.closeSync(file)
end
loadConfig()
print(table.concat(config, ","))
saveConfig()
return module