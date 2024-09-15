local require = require("customrequire")
local core = require("core")
local Object = core.Object
local Logger = require("utility.logging")
local blockModule = require("data.blocks")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local zlib = require("zlib")
local fs = require("fs")
local pathModule = require("path")
local Buffer = require("buffer").Buffer
local pb = require("networking.packetbroadcast")
local packetBroadcaster, criterias = pb.packetBroadcaster, pb.criterias
local type _ = require("networking.protocol.protocol")
local type Worlds = require("data.worlds.types")
local type World = Worlds.World
local type WorldParams = Worlds.WorldParams
local type WorldParser = Worlds.WorldParser
local type WorldModule = Worlds.WorldModule
local type Entities = require("entity.types")
local type Player = Entities.Player

local WORLD_VERSION = 3

local worlds: {string:World} = {}

local broadcasters = {
    setBlock = packetBroadcaster:new("ServerSetBlock", criterias.sameWorld),
}

local function getIndex(position:Vector3, size:Vector3): integer
    local x, y, z = position.X, position.Y, position.Z
    assert(x >= 0 and x <= size.X, "x out of bounds")
    assert(z >= 0 and z <= size.Z, "z out of bounds")
    assert(y >= 0 and y <= size.Y, "y out of bounds")
    return math.floor(x + (z * size.X) + (y * size.X * size.Z)) + 1
end


local worldClass = Object:extend() as World

function worldClass:initialize(params:WorldParams)
    local self = self as World
    self.name = params.name
    self.size = params.size
    self.spawn = params.spawn
    self.blocks = params.blocks or Buffer:new(math.floor(self.size.X * self.size.Y * self.size.Z))
    self.logger = Logger.new("World "..self.name)
    worlds[self.name] = self
    self:Save()
end
function worldClass:GetIndex(position:Vector3): integer
    return getIndex(position, self.size)
end
function worldClass:GetBlock(position:Vector3): Block
    return self.blocks:readUInt8(self:GetIndex(position)) or blockModule.BLOCK_IDS.AIR
end
function worldClass:SetBlock(position:Vector3, block:Block, dontReplicate: boolean | nil, player:Player|nil)
    self.blocks:writeUInt8(self:GetIndex(position), block)
    if not dontReplicate then
        broadcasters.setBlock:Broadcast({sourcePlayer = player}, position, block)
    end
end
function worldClass:Save()
    self.logger:Info("Saving world")
    local data = string.pack("<I4HHHHHHBB", WORLD_VERSION, self.size.X, self.size.Y, self.size.Z, self.spawn.X, self.spawn.Y, self.spawn.Z, self.spawn.yaw, self.spawn.pitch)
    local lastBlock = -1
    local count = 0
    local size = math.floor(self.size.X * self.size.Y * self.size.Z)
    local blocks = {}
    self.logger:Debug("Packing blocks for save")
    local function writeBlock(block:integer, count:integer)
        table.insert(blocks, string.pack("<BI4", block, count))
    end
    for i = 1, size do
        local block = self.blocks:readUInt8(i) or blockModule.BLOCK_IDS.AIR
        if block == lastBlock then
            count = count + 1
        else
            if count > 0 then
                writeBlock(lastBlock, count)
            end
            lastBlock = block
            count = 1
        end
    end
    if count > 0 then
        writeBlock(lastBlock, count)
    end
    self.logger:Debug("Compressing block data")
    data = data..zlib.deflate(5)(table.concat(blocks), "finish")
    if not fs.existsSync("worlds") then
        fs.mkdirSync("worlds")
    end
    self.logger:Debug("Writing world to disk")
    fs.writeFileSync("worlds/"..self.name..".hworld", data)
    self.logger:Info("World saved")
end
function worldClass:Pack(protocol:Protocol): string
    local function compress(str:string): string
        local level = 5
        local windowSize = 15+16
        return zlib.deflate(level, windowSize)(str, "finish")
    end
    self.logger:Debug("Packing world")
    
    local totalSize = math.floor(self.size.X * self.size.Z * self.size.Y)
    local data = string.pack(">I4", totalSize)
    local blockData = self.blocks
    local airBlock = blockModule.BLOCK_IDS.AIR
    local protoRepl = blockModule.replacements.REPLACEMENT_INFO[protocol.Meta.Version]
    
    local default: Block
    local repl: {Block: Block}
    local max:Block

    if protoRepl then
        default = blockModule.replacements.DEFAULT
        repl = blockModule.replacements.REPLACEMENTS
        max = protoRepl.MAX
    end
    
    local blocks = Buffer:new(totalSize)
    self.logger:Debug("Packing blocks")
    for i = 1, totalSize do
        local block = blockData:readUInt8(i)
        if protoRepl and block and block > max then
            block = repl[block] or default
        end
        blocks:writeUInt8(i, block or airBlock)
    end
    
    data = data .. blocks:toString()
    self.logger:Debug("Compressing world")
    return compress(data)
end

local parsers: {string:WorldParser} 
parsers = {
    ["hworld"] = require("data.worlds.importers.hworld")
}

local worldModule = Object:extend() as WorldModule

function worldModule:initialize()
    local self = self as WorldModule
    self.logger = Logger.new("WorldModule")
end

function worldModule:newWorld(name:string, size:Vector3): World
    local blocks = Buffer:new(math.floor(size.X * size.Y * size.Z))
    local stone, dirt, grass = blockModule.BLOCK_IDS.STONE, blockModule.BLOCK_IDS.DIRT, blockModule.BLOCK_IDS.GRASS
    for x = 0, size.X-1 do
        for y = 0, size.Y // 2.5  do
            for z = 0, size.Z-1 do
                if y < 59 then
                    blocks:writeUInt8(getIndex(Vector3.new(x, y, z, true), size), stone)
                elseif y < 63 then
                    blocks:writeUInt8(getIndex(Vector3.new(x, y, z, true), size), dirt)
                else
                    blocks:writeUInt8(getIndex(Vector3.new(x, y, z, true), size), grass)
                end
            end
        end
    end
    return worldClass:new({blocks = blocks, name = name, size = size, spawn = EntityPosition.new(0,0,0,0,0)}) as World
end
function worldModule:load(path:string): World|nil
    local name = pathModule.basename(path):match("(.+)%..+")
    local filetype = pathModule.basename(path):match(".+%.(.+)")
    if worlds[name] then
        return worlds[name]
    end
    if not fs.existsSync(path) then
        self.logger:Error("World file not found: "..path)
    end
    local data = fs.readFileSync(path)
    local version = parsers[filetype]:getVersion(data)
    local parser = parsers[filetype].versions[version]
    if not parser then
        self.logger:Error("Unsupported world version: "..version)
    end
    return worldClass:new(parser(name, data)) as World
end
function worldModule:loadOrCreate(name:string, filetype:string, size:Vector3): World
    local path = string.format("worlds/%s.%s", name, filetype)
    local world:World
    if not fs.existsSync(path) then
        world = self:newWorld(name, size)
    else
        world = self:load(path)
    end
    return world
end
function worldModule:saveAll()
    for _, world in pairs(worlds) do
        world:Save()
    end
end
function worldModule:getWorld(name:string): World|nil
    return worlds[name]
end


return worldModule:new()