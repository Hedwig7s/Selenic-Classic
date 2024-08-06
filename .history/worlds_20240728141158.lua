local module = {}
local fs = require("fs")
local numberutil = require("./numberutil")
local util = require("./util")

module.BLOCK_IDS = {
    AIR = 0,
    STONE = 1,
    GRASS = 2,
    DIRT = 3,
    COBBLESTONE = 4,
    WOOD_PLANKS = 5,
    SAPLING = 6,
    BEDROCK = 7,
    WATER = 8,
    STATIONARY_WATER = 9,
    LAVA = 10,
    STATIONARY_LAVA = 11,
    SAND = 12,
    GRAVEL = 13,
    GOLD_ORE = 14,
    IRON_ORE = 15,
    COAL_ORE = 16,
    WOOD = 17,
    LEAVES = 18,
    SPONGE = 19,
    GLASS = 20,
    RED = 21,
    ORANGE = 22,
    YELLOW = 23,
    LIME = 24,
    GREEN = 25,
    SPRING_GREEN = 26,
    CYAN = 27,
    LIGHT_BLUE = 28,
    BLUE = 29,
    VIOLET = 30,
    PURPLE = 31,
    MAGENTA = 32,
    PINK = 33,
    BLACK = 34,
    GRAY = 35,
    WHITE = 36,
    DANDELION = 37,
    ROSE = 38,
    BROWN_MUSHROOM = 39,
    RED_MUSHROOM = 40,
    GOLD = 41,
    IRON = 42,
    DOUBLE_SLAB = 43,
    SLAB = 44,
    BRICK = 45,
    TNT = 46,
    BOOKSHELF = 47,
    MOSSY_COBBLESTONE = 48,
    OBSIDIAN = 49,
}

function module.getBlockName(id)
    for k, v in pairs(module.BLOCK_IDS) do
        if v == id then
            return k
        end
    end
    return "UNKNOWN"
end

local World = {}
World.__index = World



return module