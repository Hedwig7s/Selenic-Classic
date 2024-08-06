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

local function getIndex(x, y, z, size)
    assert(x >= 0 and x <= size.x, "x out of bounds")
    assert(z >= 0 and z <= size.z, "z out of bounds")
    assert(y >= 0 and y <= size.y, "y out of bounds")
    return x + (z * size.x) + (y * size.x * size.z)
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
    print("Saving world "..self.name)
    print("Creating header")
    data = data .. numberutil:tou16(self.size.x)..numberutil:tou16(self.size.y)..numberutil:tou16(self.size.z)
    data = data .. numberutil:tou16(self.spawn.x)..numberutil:tou16(self.spawn.y)..numberutil:tou16(self.spawn.z)
    local lastBlock = -1
    local count = 0
    print("Creating block data")
    for i = 0, self.size.x*self.size.z*self.size.y do
        local block = self.blocks[i] or module.BLOCK_IDS.AIR
        if block == lastBlock then
            count = count + 1
        else
            if count > 0 then
                data = data .. numberutil:tou8(lastBlock) .. numberutil:tou32(count)
            end
            lastBlock = block
            count = 1
        end
    end
    if not fs.existsSync("./worlds") then
        fs.mkdirSync("./worlds")
    end
    print("Writing to file")
    fs.writeFileSync("./worlds/"..self.name .. ".hworld", data)
    print("World saved")
end

function World.new(name, size, spawn, blocks)
    local self = setmetatable({}, World)
    self.name = name
    self.size = util.deepCopy(size)
    self.spawn = util.deepCopy(spawn) or {x = 0, y = 0, z = 0}
    self.blocks = blocks or {}
    return self
end

function module:load(name)
    local data = fs.readFileSync("./worlds/"..name..".hworld")
    local sizeX = numberutil:fromu16(data:sub(1, 2))
    local sizeY = numberutil:fromu16(data:sub(3, 4))
    local sizeZ = numberutil:fromu16(data:sub(5, 6))
    local spawnX = numberutil:fromu16(data:sub(7, 8))
    local spawnY = numberutil:fromu16(data:sub(9, 10))
    local spawnZ = numberutil:fromu16(data:sub(11, 12))
    local blocks = {}
    for i = 13, #data, 5 do
        local block = numberutil:fromu8(data:sub(i, i))
        local count = numberutil:fromu32(data:sub(i + 1, i + 4))
        for j = 1, count do
            table.insert(blocks, block)
        end
    end
    return World.new(name, {x = sizeX, y = sizeY, z = sizeZ}, {x = spawnX, y = spawnY, z = spawnZ}, blocks)
end

function module:loadOrCreate(name)
    if fs.existsSync("./worlds/"..name..".hworld") then
        return module:load(name)
    else
        local world = World.new(name, {x = 256, y = 128, z = 256})
        for x = 0, world.size.x do
            for z = 0, world.size.z do
                for y = 0, 64 do
                    if y == 0 then
                        world:setBlock(x, y, z, module.BLOCK_IDS.BEDROCK)
                    elseif y < 60 then
                        world:setBlock(x, y, z, module.BLOCK_IDS.STONE)
                    elseif y < 64 then
                        world:setBlock(x, y, z, module.BLOCK_IDS.DIRT)
                    elseif y == 64 then
                        world:setBlock(x, y, z, module.BLOCK_IDS.GRASS)
                    end
                end
            end
        end
        return world
    end

end

return module