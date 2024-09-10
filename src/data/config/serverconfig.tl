local require = require("customrequire")
local configClass = require("data.config.config")

local serverConfig = configClass:new("server", {
    server = {
        host = "0.0.0.0",
        port = 25565,
        maxPlayers = 20,
        motd = "A Minecraft Server",
        debug = false,
        serverName = "Selenic Server",
        defaultWorld = "world",
        localBypassVerification = false,
        verifyNames = true,
    }
})

return serverConfig