local require = require("customrequire")
local serverClass = require("networking/server")

local server = serverClass("0.0.0.0", 25565)
server:init()