local worlds = require("./worlds")

local world = worlds:loadOrCreate("test")
print(world:getBlock(0, 0, 0), world:getBlock(0, 5, 0), world:getBlock(0, 63, 0), world:getBlock(0, 65, 0))
world:save()