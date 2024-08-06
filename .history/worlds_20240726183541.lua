local module = {}
local fs = require("fs")

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

local function getIndex(x, y, z, size)
    assert(x >= 0 and x < size.x, "x out of bounds")
    assert(y >= 0 and y < size.y, "y out of bounds")
    assert(z >= 0 and z < size.z, "z out of bounds")
    return x + (y *size.x) + (z * size.x * size.y)
end

function World:setBlock(x, y, z, id)
    local index = getIndex(x, y, z, self.size)
    self.blocks[index] = id
end

function World:getBlock(x, y, z)
    local index = getIndex(x, y, z, self.size)
    return self.blocks[index] or module.BLOCK_IDS.AIR
end

function World:save()
    local data = ""
    for i = 0, self.size.x-1 do
        for j = 0, self.size.y-1 do
            for k = 0, self.size.z-1 do
                data = data .. string.char(self:getBlock(i, j, k))
            end
        end
    end
    if not fs.existsSync("./worlds") then
        fs.mkdirSync("./worlds")
    end
    fs.writeFileSync("./worlds/"..self.name .. ".world", data)
end

function World.new(name, sizeX, sizeY, sizeZ)
    local self = setmetatable({}, World)
    self.name = name
    self.size = {x = sizeX, y = sizeY, z = sizeZ}
    self.spawn = {x = 0, y = 0, z = 0}
    self.blocks = {}
    return self
end

return module