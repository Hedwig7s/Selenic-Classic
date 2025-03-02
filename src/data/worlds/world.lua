local require = require("customrequire")
local class = require("middleclass")
local Logger = require("utility.logging")
local blockModule = require("data.blocks")
local Vector3 = require("datatypes.vector3")
local zlib = require("zlib")
local fs = require("fs")
local Buffer = require("buffer").Buffer
local pb = require("networking.packetbroadcast")
local packetBroadcaster, criterias = pb.packetBroadcaster, pb.criterias
local serverConfig = require("data.config.serverconfig")
local _ = require("networking.protocol.protocol")

local WORLD_VERSION = 3

local broadcasters = {
	setBlock = packetBroadcaster:new("ServerSetBlock", criterias.sameWorld),
}

local function getIndex(position, size)
	local x, y, z = position.X, position.Y, position.Z
	assert(x >= 0 and x <= size.X, "x out of bounds")
	assert(z >= 0 and z <= size.Z, "z out of bounds")
	assert(y >= 0 and y <= size.Y, "y out of bounds")
	return math.floor(x + (z * size.X) + (y * size.X * size.Z)) + 1
end

local worldClass = class("World")

function worldClass:initialize(params)
	local self = self
	self.name = params.name
	self.size = params.size
	self.spawn = params.spawn
	self.autosave = params.autosave or false
	self.blocks = params.blocks or Buffer:new(math.floor(self.size.X * self.size.Y * self.size.Z))
	self.logger = Logger.new("World " .. self.name)
	if self.autosave then
		self:Save()
	end
end
function worldClass:GetIndex(position)
	return getIndex(position, self.size)
end
function worldClass:GetBlock(position)
	return self.blocks:readUInt8(self:GetIndex(position)) or blockModule.BLOCK_IDS.AIR
end
function worldClass:SetBlock(position, block, dontReplicate, player)
	self.blocks:writeUInt8(self:GetIndex(position), block)
	if not dontReplicate then
		broadcasters.setBlock:Broadcast({ sourcePlayer = player }, position, block)
	end
end
function worldClass:Save()
	self.logger:Info("Saving world")
	local data = string.pack(
		"<I4HHHHHHBB",
		WORLD_VERSION,
		self.size.X,
		self.size.Y,
		self.size.Z,
		self.spawn.X,
		self.spawn.Y,
		self.spawn.Z,
		self.spawn.yaw,
		self.spawn.pitch
	)
	local lastBlock = -1
	local count = 0
	local size = math.floor(self.size.X * self.size.Y * self.size.Z)
	local blocks = {}
	self.logger:Debug("Packing blocks for save")
	local function writeBlock(block, count)
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
	data = data .. zlib.deflate(5)(table.concat(blocks), "finish")
	if not fs.existsSync("worlds") then
		fs.mkdirSync("worlds")
	end
	self.logger:Debug("Writing world to disk")
	local filePath = "worlds/" .. self.name .. ".hworld"
	if serverConfig:get("server.backupWorldsOnSave") == true and fs.existsSync(filePath) then
		if fs.existsSync(filePath .. ".bak") then
			fs.unlinkSync(filePath .. ".bak")
		end
		fs.renameSync(filePath, filePath .. ".bak")
	end
	fs.writeFileSync(filePath, data)
	self.logger:Info("World saved")
end
function worldClass:Pack(protocol)
	self.logger:Debug("Packing world")

	local totalSize = math.floor(self.size.X * self.size.Z * self.size.Y)
	local data = string.pack(">I4", totalSize)
	local blockData = self.blocks
	local airBlock = blockModule.BLOCK_IDS.AIR
	local protoRepl = blockModule.replacements.REPLACEMENT_INFO[protocol.Meta.Version]

	local default
	local repl
	local max

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
	return zlib.deflate(5, 31)(data, "finish")
end

return {
	World = worldClass,
	GetIndex = getIndex,
}
