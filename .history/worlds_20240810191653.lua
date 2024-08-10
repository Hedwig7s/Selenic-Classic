---@class WorldsModule
local module = {}
local fs = require("fs")
local util = require("./util")
local zlib = require("zlib")
local packets
require("compat53")

local WORLD_VERSION = 2 -- Update for any breaking changes

---@type table<string,World> 
module.loadedWorlds = {}

---@enum BlockIDs
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

---Gets internal block name from id
---@param id BlockIDs
---@return string
function module.getBlockName(id)
    for k, v in pairs(module.BLOCK_IDS) do
        if v == id then
            return k
        end
    end
    return "UNKNOWN"
end


---@class World
---@field name string
---@field size Vector3
---@field spawn Position
---@field blocks table<number, BlockIDs>
local World = {}
World.__index = World

---@param x number
---@param y number
---@param z number
---@param size Vector3
---@return number
local function getIndex(x, y, z, size)
    assert(x >= 0 and x <= size.x, "x out of bounds")
    assert(z >= 0 and z <= size.z, "z out of bounds")
    assert(y >= 0 and y <= size.y, "y out of bounds")
    return x + (z * size.x) + (y * size.x * size.z)
end

---Sets block at specified x, y and z coordinates
---@param x number
---@param y number
---@param z number
---@param id BlockIDs
---@param skipSend boolean?
function World:setBlock(x, y, z, id, skipSend)
    local index = getIndex(x, y, z, self.size)
    self.blocks[index] = id
    if not packets then 
        packets = require("./packets")
    end
    if not skipSend then
        packets.ServerPackets.SetBlock(x, y, z, id)
    end
end

---Gets block at specified x, y and z coordinates
---@param x number
---@param y number
---@param z number
---@return BlockIDs
function World:getBlock(x, y, z)
    local index = getIndex(x, y, z, self.size)
    return self.blocks[index] or module.BLOCK_IDS.AIR
end

---Saves the world to a file
function World:save()
    print("Saving world "..self.name)
    print("Creating header")
    local data = string.pack("I4HHHHHHBB", WORLD_VERSION,self.size.x, self.size.y,self.size.z, self.spawn.x,self.spawn.y,self.spawn.z, self.spawn.yaw, self.spawn.pitch)
    local lastBlock = -1
    local count = 0
    print("Creating block data")
    for i = 1, self.size.x*self.size.z*self.size.y+1 do
        local block = self.blocks[i] or module.BLOCK_IDS.AIR
        if block == lastBlock then
            count = count + 1
        else
            if count > 0 then
                data = data .. string.pack("BI4",lastBlock,count)
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

---Sets the spawn point of the world
---@param x number
---@param y number
---@param z number
function World:setSpawn(x, y, z)
    self.spawn = {x = x, y = y, z = z}
end

---Packs the world into a protocol-compliant byte-array
---@return string
function World:Pack()
    local function compress(str)
        local level = 5
        local windowSize = 15+16
        return zlib.deflate(level, windowSize)(str, "finish")
    end
    print("Packing world")
    local data = string.pack(">I4", self.size.x*self.size.z*self.size.y)
    local lastPercent = 0
    local blocks = {}
    local totalSize = self.size.x * self.size.z * self.size.y
    local blockData = self.blocks
    local airBlock = module.BLOCK_IDS.AIR
    
    for i = 1, totalSize do
        blocks[i] = string.pack(">B",blockData[i] or airBlock)
        local percent = math.floor(i / totalSize * 100)
        if percent ~= lastPercent then
            print("Packing: " .. percent .. "%")
            lastPercent = percent
        end
    end
    
    data = data .. table.concat(blocks)
    print("Compressing")
    return compress(data) 
end

---Creates a new world
---@param name string
---@param size Vector3?
---@param spawn Position?
---@param blocks table<BlockIDs>?
---@return World
function World.new(name, size, spawn, blocks)
    local self = setmetatable({}, World)
    self.name = name
    self.size = util.deepCopy(size)
    self.spawn = util.deepCopy(spawn) or {x = 0, y = 0, z = 0, yaw = 0, pitch = 0}
    self.blocks = blocks or {}
    module.loadedWorlds[name] = self
    return self
end

---Loads a world from a file
---@param name string
---@return World
function module:load(name)
    local data = fs.readFileSync("./worlds/"..name..".hworld")
    local version, sizeX, sizeY, sizeZ, spawnX, spawnY, spawnZ, spawnYaw, spawnPitch = string.unpack("I4HHHHHHBB",data:sub(1, 18))
    local blocks = {}
    data = data:sub(19)
    for i = 1, #data, 5 do
        local block, count = string.unpack("BI4",data:sub(i, i+4))
        for _ = 1, count do
            table.insert(blocks, block)
        end
        
    end
    return World.new(name, {x = sizeX, y = sizeY, z = sizeZ}, {x = spawnX, y = spawnY, z = spawnZ, yaw = spawnYaw, pitch = spawnPitch}, blocks)
end

---Loads a world from a file, or creates a new one if it doesn't exist
---@param name string
---@return World
function module:loadOrCreate(name)
    if module.loadedWorlds[name] then
        return module.loadedWorlds[name]
    elseif fs.existsSync("./worlds/"..name..".hworld") then
        return module:load(name)
    else
        local world = World.new(name, {x = 256, y = 128, z = 256}, {x = 128, y = 70, z = 128, pitch = 0, yaw = 0})
        for x = 0, world.size.x - 1 do
            for z = 0, world.size.z - 1 do
                for y = 0, world.size.y/2 do
                    if y < 59 then
                        world:setBlock(x, y, z, module.BLOCK_IDS.STONE, true)
                    elseif y < 63 then
                        world:setBlock(x, y, z, module.BLOCK_IDS.DIRT, true)
                    elseif y == 63 then
                        world:setBlock(x, y, z, module.BLOCK_IDS.GRASS, true)
                    end
                end
            end
        end
        return world
    end
end

---Saves all loaded worlds  
function module:saveAll()
    for _, v in pairs(module.loadedWorlds) do
        v:save()
    end
end

return module