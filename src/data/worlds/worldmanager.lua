local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")
local blockModule = require("data.blocks")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local fs = require("fs")
local pathModule = require("path")
local Buffer = require("buffer").Buffer
local _ = require("networking.protocol.protocol")

local worldNamespace = require("data.worlds.world")
local getIndex = worldNamespace.GetIndex
local worldClass = worldNamespace.World

local worlds = {}

local parsers
parsers = {
	["hworld"] = require("data.worlds.importers.hworld"),
}

local worldManager = class("WorldManager")

function worldManager:initialize()
	local self = self
	self.logger = Logger.new("WorldManager")
end

function worldManager:registerWorld(world)
	if worlds[world.name] then
		error(self.logger:FormatErr("World already exists: " .. world.name))
	end
	worlds[world.name] = world
end

function worldManager:newWorld(name, size)
	local blocks = Buffer:new(math.floor(size.X * size.Y * size.Z))
	local stone, dirt, grass = blockModule.BLOCK_IDS.STONE, blockModule.BLOCK_IDS.DIRT, blockModule.BLOCK_IDS.GRASS
	for x = 0, size.X - 1 do
		for y = 0, math.floor(size.Y / 2.5) do
			for z = 0, size.Z - 1 do
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
	local world = worldClass:new({
		blocks = blocks,
		name = name,
		size = size,
		spawn = EntityPosition.new(0, 0, 0, 0, 0),
		autosave = true,
	})
	self:registerWorld(world)
	return world
end
function worldManager:load(path)
	local name = pathModule.basename(path):match("(.+)%..+")
	local filetype = pathModule.basename(path):match(".+%.(.+)")
	if worlds[name] then
		return worlds[name]
	end
	if not fs.existsSync(path) then
		error(self.logger:FormatErr("World file not found: " .. path))
	end
	local data = fs.readFileSync(path)
	local version = parsers[filetype]:getVersion(data)
	local parser = parsers[filetype].versions[version]
	if not parser then
		error(self.logger:FormatErr("Unsupported world version version " .. version))
	end
	local worldData = parser(name, data)
	worldData.autosave = true
	local world = worldClass:new(worldData)
	self:registerWorld(world)
	return world
end
function worldManager:loadOrCreate(name, filetype, size)
	local path = string.format("worlds/%s.%s", name, filetype)
	local world
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
function worldManager:getWorld(name)
	return worlds[name]
end
function worldManager:registerParser(filetype, parser)
	if parsers[filetype] then
		self.logger:Warn("Overwriting parser for filetype: " .. filetype)
	end
	parsers[filetype] = parser
end

return worldManager:new()
