local require = require("customrequire")
local configClass = require("data.config.config")

local serverConfig = configClass:new("server", 1, {
    server = {
        host = "0.0.0.0",
        port = 25565,
        maxPlayers = 20,
        motd = "A Selenic Server",
        debug = false,
        serverName = "Selenic Server",
        defaultWorld = "world",
        localBypassVerification = false,
        verifyNames = true,
    },
    heartbeat = {
        enabled = true,
        public = true,
        interval = 10000,
        url = "http://www.classicube.net/server/heartbeat/"
    }
})

return serverConfig