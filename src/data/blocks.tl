local require = require("customrequire")

local record replacementInfo
    MAX: integer
end

local record replacements
    DEFAULT: Block
    REPLACEMENTS: {Block: Block}
    REPLACEMENT_INFO: {integer: replacementInfo}
end



global type Block = integer
global type BlockData = integer -- TODO: Blocks with data

global record BlocksModule
    BLOCK_IDS: {string: Block}
    replacements:replacements
    getBlockName: function(self:BlocksModule, id:Block): string
end

BlocksModule.BLOCK_IDS = {
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
BlocksModule.getBlockName = function(self:BlocksModule, id:integer): string
    for name, blockId in pairs(self.BLOCK_IDS) do
        if blockId == id then
            return name
        end
    end
    return "UNKNOWN"
end
BlocksModule.replacements = {
    DEFAULT = BlocksModule.BLOCK_IDS.STONE,
    REPLACEMENT_INFO = {
        [1] = {
            MAX = BlocksModule.BLOCK_IDS.LEAVES,
        },
        [6] = {
            MAX = BlocksModule.BLOCK_IDS.GOLD,
        },
        [5] = {
            MAX = BlocksModule.BLOCK_IDS.GLASS,
        },
        [4] = {
            MAX = BlocksModule.BLOCK_IDS.LEAVES,
        },
        [3] = {
            MAX = BlocksModule.BLOCK_IDS.LEAVES,
        },
    },

    REPLACEMENTS = {
        [BlocksModule.BLOCK_IDS.SPONGE] = BlocksModule.BLOCK_IDS.SAND,
        [BlocksModule.BLOCK_IDS.GLASS] = BlocksModule.BLOCK_IDS.GRAVEL,
        [BlocksModule.BLOCK_IDS.YELLOW] = BlocksModule.BLOCK_IDS.SAND,
        [BlocksModule.BLOCK_IDS.LIME] = BlocksModule.BLOCK_IDS.LEAVES,
        [BlocksModule.BLOCK_IDS.GREEN] = BlocksModule.BLOCK_IDS.LEAVES,
        [BlocksModule.BLOCK_IDS.SPRING_GREEN] = BlocksModule.BLOCK_IDS.LEAVES,
        [BlocksModule.BLOCK_IDS.GRAY] = BlocksModule.BLOCK_IDS.STONE,
        [BlocksModule.BLOCK_IDS.WHITE] = BlocksModule.BLOCK_IDS.STONE,
        [BlocksModule.BLOCK_IDS.DANDELION] = BlocksModule.BLOCK_IDS.AIR,
        [BlocksModule.BLOCK_IDS.ROSE] = BlocksModule.BLOCK_IDS.AIR,
        [BlocksModule.BLOCK_IDS.BROWN_MUSHROOM] = BlocksModule.BLOCK_IDS.AIR,
        [BlocksModule.BLOCK_IDS.RED_MUSHROOM] = BlocksModule.BLOCK_IDS.AIR,
        [BlocksModule.BLOCK_IDS.GOLD] = BlocksModule.BLOCK_IDS.GOLD_ORE,
        [BlocksModule.BLOCK_IDS.IRON] = BlocksModule.BLOCK_IDS.IRON_ORE,
        [BlocksModule.BLOCK_IDS.DOUBLE_SLAB] = BlocksModule.BLOCK_IDS.STONE,
        [BlocksModule.BLOCK_IDS.MOSSY_COBBLESTONE] = BlocksModule.BLOCK_IDS.COBBLESTONE,
    }
} 

return BlocksModule