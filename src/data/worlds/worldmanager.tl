local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")
local blockModule = require("data.blocks")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local fs = require("fs")
local pathModule = require("path")
local Buffer = require("buffer").Buffer
local type _ = require("networking.protocol.protocol")
local type Worlds = require("data.worlds.types")
local type World = Worlds.World
local type WorldParser = Worlds.WorldParser
local type WorldManager = Worlds.WorldManager
local worldNamespace = require("data.worlds.world")
local getIndex = worldNamespace.GetIndex
local worldClass = worldNamespace.World

local worlds: {string:World} = {}

local parsers: {string:WorldParser} 
parsers = {
    ["hworld"] = require("data.worlds.importers.hworld")
}

local worldManager = class("WorldManager") as WorldManager

function worldManager:initialize()
    local self = self as WorldManager
    self.logger = Logger.new("WorldManager")
end

function worldManager:registerWorld(world:World)
    if worlds[world.name] then
        error(self.logger:FormatErr("World already exists: "..world.name))
    end
    worlds[world.name] = world
end

function worldManager:newWorld(name:string, size:Vector3): World
    local blocks = Buffer:new(math.floor(size.X * size.Y * size.Z))
    local stone, dirt, grass = blockModule.BLOCK_IDS.STONE, blockModule.BLOCK_IDS.DIRT, blockModule.BLOCK_IDS.GRASS
    for x = 0, size.X-1 do
        for y = 0, size.Y // 2.5  do
            for z = 0, size.Z-1 do
                if y < 59 then
                    blocks:writeUInt8(getIndex(Vector3.new(x, y, z), size), stone)
                elseif y < 63 then
                    blocks:writeUInt8(getIndex(Vector3.new(x, y, z), size), dirt)
                else
                    blocks:writeUInt8(getIndex(Vector3.new(x, y, z), size), grass)
                end
            end
        end
    end
    local world = worldClass:new({blocks = blocks, name = name, size = size, spawn = EntityPosition.new(0,0,0,0,0), autosave = true}) as World
    self:registerWorld(world)
    return world
end
function worldManager:load(path:string): World|nil
    local name = pathModule.basename(path):match("(.+)%..+")
    local filetype = pathModule.basename(path):match(".+%.(.+)")
    if worlds[name] then
        return worlds[name]
    end
    if not fs.existsSync(path) then
        error(self.logger:FormatErr("World file not found: "..path))
    end
    local data = fs.readFileSync(path)
    local version = parsers[filetype]:getVersion(data)
    local parser = parsers[filetype].versions[version]
    if not parser then
        error(self.logger:FormatErr("Unsupported world version version "..version))
    end
    local worldData = parser(name, data)
    worldData.autosave = true
    local world = worldClass:new(worldData) as World
    self:registerWorld(world)
    return world
end
function worldManager:loadOrCreate(name:string, filetype:string, size:Vector3): World
    local path = string.format("worlds/%s.%s", name, filetype)
    local world:World
    if not fs.existsSync(path) then
        world = self:newWorld(name, size)
    else
        world = self:load(path)
    end
    return world
end
function worldManager:saveAll()
    for _, world in pairs(worlds) do
        if world.autosave then
            world:Save()
        end
    end
end
function worldManager:getWorld(name:string): World|nil
    return worlds[name]
end
function worldManager:registerParser(filetype:string, parser:WorldParser)
    if parsers[filetype] then
        self.logger:Warn("Overwriting parser for filetype: "..filetype)
    end
    parsers[filetype] = parser
end

return worldManager:new()