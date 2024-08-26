local require = require("customrequire")
local class = require("class")
local logging = require("logging")
local blockModule = require("data.blocks")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local zlib = require("zlib")
local fs = require("fs")
local type _ = require("networking.protocol.protocol")
local type _ = require("data.worlds.types")

local WORLD_VERSION = 3

local worlds: {string:World} = {}

global record World 
    __class__: BaseClass
    name: string
    size: Vector3
    spawn: EntityPosition
    blocks: {integer: Block}
    logger: Logger
    Pack: function(protocol:Protocol): string
    GetBlock: function(self:World, position:Vector3): Block
    SetBlock: function(self:World, position:Vector3, block:Block)
    Save: function(self:World)
end

local function getIndex(position:Vector3, size:Vector3): integer
    local x, y, z = position.x, position.y, position.z
    assert(x >= 0 and x <= size.x, "x out of bounds")
    assert(z >= 0 and z <= size.z, "z out of bounds")
    assert(y >= 0 and y <= size.y, "y out of bounds")
    return math.floor(x + (z * size.x) + (y * size.x * size.z) + 1)
end


local worldClass = class("World", {
    singleton = false,
    constructor = function(self:Instance, params:WorldParams)
        local self = self as World
        self.name = params.name
        self.size = params.size
        self.spawn = params.spawn
        self.blocks = params.blocks or {}
        self.logger = logging.new("World "..self.name)
        worlds[self.name] = self
    end,
    values = {
        GetBlock = function(self:World, position:Vector3): Block
            return self.blocks[getIndex(position, self.size)] or blockModule.BLOCK_IDS.AIR
        end,
        SetBlock = function(self:World, position:Vector3, block:Block)
            self.blocks[getIndex(position, self.size)] = block
        end,
        Save = function(self:World)
            local data = string.pack("<I4HHHHHHBB", WORLD_VERSION, self.size.x, self.size.y, self.size.z, self.spawn.position.x, self.spawn.position.y, self.spawn.position.z, self.spawn.yaw, self.spawn.pitch)
            local lastBlock = -1
            local count = 0 
            local blocks = {}
            for i = 1 , self.size.x * self.size.y * self.size.z do
                local block = self.blocks[i as integer] or blockModule.BLOCK_IDS.AIR
                if block == lastBlock then
                    count = count + 1
                else
                    if count > 0 then
                        table.insert(blocks, string.pack("<BI4", lastBlock, count))
                    end
                    lastBlock = block
                    count = 1
                end
            end
            if count > 0 then
                table.insert(blocks, string.pack("<BI4", lastBlock, count))
            end
            data = data..zlib.deflate(5)(table.concat(blocks))
            if not fs.existsSync("worlds") then
                fs.mkdirSync("worlds")
            end
            fs.writeFileSync("worlds/"..self.name..".hworld", data)
        end,
        Pack = function(self:World, protocol:Protocol): string
            local function compress(str:string): string
                local level = 5
                local windowSize = 15+16
                return zlib.deflate(level, windowSize)(str, "finish")
            end
            self.logger:Debug("Packing world")
            -- This is very verbose but if it wasn't it would be incredibly slow
            local data = string.pack(">I4", self.size.x*self.size.z*self.size.y) 
            local blocks = {}
            local totalSize = self.size.x * self.size.z * self.size.y
            local blockData = self.blocks
            local airBlock = blockModule.BLOCK_IDS.AIR
            local replacements = blockModule.replacements
            local protoRepl = replacements.REPLACEMENT_INFO[protocol.Meta.Version]
            local default: Block
            local repl: {Block: Block}
            local max:Block
            if protoRepl then
                default = replacements.DEFAULT
                repl = replacements.REPLACEMENTS
                max = protoRepl.MAX
            end
            for i = 1, totalSize do
                local block = blockData[i as integer]
                if protoRepl and block and block > max then
                    block = repl[block] or default
                end
                blocks[i] = string.pack(">B",block or airBlock)
            end
            
            data = data .. table.concat(blocks)
            self.logger:Debug("Compressing world")
            return compress(data) 
        end
    }
})



local parsers: {string:WorldParser} 
parsers = {
    ["hworld"] = require("data.worlds.importers.hworld")
}

global record WorldModule
    new: function(name:string, size:Vector3): World
    load: function(name:string, filetype:string): World
    loadOrCreate: function(name:string, filetype:string, size:Vector3): World
    saveAll: function()
end

WorldModule.new = function(name:string, size:Vector3): World
    local blocks = {}
    local stone, dirt, grass = blockModule.BLOCK_IDS.STONE, blockModule.BLOCK_IDS.DIRT, blockModule.BLOCK_IDS.GRASS
    for x = 0, size.x-1 do
        for y = 0, 63 do
            for z = 0, size.z-1 do
                if y < 59 then
                    blocks[getIndex(Vector3.new(x, y, z, true), size)] = stone
                elseif y < 63 then
                    blocks[getIndex(Vector3.new(x, y, z, true), size)] = dirt
                else
                    blocks[getIndex(Vector3.new(x, y, z, true), size)] = grass
                end
            end
        end
    end
    return worldClass({blocks = blocks, name = name, size = size, spawn = EntityPosition.new(0,0,0,0,0)}) as World
end

WorldModule.load = function(name:string, filetype:string): World|nil
    local path = string.format("worlds/%s.%s", name, filetype)
    if not fs.existsSync(path) then
        error("World file not found: "..path)
    end
    local data = fs.readFileSync(path)
    local version = parsers[filetype]:getVersion(data)
    local parser = parsers[filetype].versions[version]
    if not parser then
        error("Unsupported world version: "..version)
    end
    return worldClass(parser(name, data)) as World
end

WorldModule.loadOrCreate = function(name:string, filetype:string, size:Vector3): World
    local success, world = pcall(WorldModule.load,name, filetype)
    if not success then
        world = WorldModule.new(name, size)
    end
    return world
end

WorldModule.saveAll = function()
    for _, world in pairs(worlds) do
        world:Save()
    end
end

return WorldModule