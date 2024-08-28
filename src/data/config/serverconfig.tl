local require = require("customrequire")
local configClass = require("data.config.config")

local serverConfig = configClass("server", {
    server = {
        port = 25565,
        maxPlayers = 20,
        motd = "A Minecraft Server",
        debug = false,
        serverName = "Selenic Server",
        defaultWorld = "world",
    }
})

return serverConfig