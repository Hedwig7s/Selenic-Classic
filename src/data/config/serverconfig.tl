local configClass = require("data.config.config")

local serverConfig = configClass("ServerConfig", {
    defaults = {
        port = 25565,
        maxPlayers = 20,
        motd = "A Minecraft Server",
        debug = false,
    }
})