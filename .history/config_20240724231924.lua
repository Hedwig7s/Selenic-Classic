local toml = require("toml")
local fs = require("fs")

local function loadConfig()
    local file = io.open("config.toml", "r")
    if not file then
        return {}
    end
    local data = file:read("*a")
    file:close()
    return toml.parse(data)
end