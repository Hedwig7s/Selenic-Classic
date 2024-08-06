local worlds = require("./worlds")

local world = worlds:loadOrCreate("test")
world:save()