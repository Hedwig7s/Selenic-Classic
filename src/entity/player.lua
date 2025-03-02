local require = require("customrequire")
local class = require("middleclass")

local _ = require("networking.protocol.protocol")

local EntityPosition = require("datatypes.entityposition")
local entityClass = require("entity.entity")
local Logger = require("utility.logging")
local pb = require("networking.packetbroadcast")
local broadcasterClass = pb.packetBroadcaster
local criterias = pb.criterias
local combineCriterias = pb.combineCriterias
local playerRegistry = require("entity.playerregistry")
local chat = require("messaging.chat")
local messageCriterias = require("messaging.criterias")

local broadcasters = {
	spawn = broadcasterClass:new("SpawnPlayer", criterias.sameWorld),
	despawn = broadcasterClass:new("DespawnPlayer", criterias.sameWorld),
	positionAndOrientation = broadcasterClass:new(
		"PositionAndOrientation",
		combineCriterias(criterias.sameWorld, criterias.notSelf)
	),
}

local playerClass = entityClass:subclass("Player")

function playerClass:initialize(name, connection)
	local super = entityClass.initialize
	super(self, name)
	local self = self
	self.fancyName = name
	self.connection = connection
	self.logger = Logger.new("Player " .. self.name)
	self.logger:Debug("Registering player")
	playerRegistry:RegisterEntity(self, self.id)
end

function playerClass:MoveTo(position, dontReplicate, clientMovement)
	local super = entityClass.MoveTo
	super(self, position, true)
	if not dontReplicate then
		broadcasters.positionAndOrientation:Broadcast({ sourcePlayer = self }, self.position)
	end
end
function playerClass:Spawn()
	local super = entityClass.Spawn
	super(self)
	broadcasters.spawn:Broadcast({ sourcePlayer = self }, self.fancyName, self.position)
	for _, player in ipairs(playerRegistry:GetEntities()) do
		local player = player
		broadcasters.spawn:sendTo(self, { sourcePlayer = player }, player.fancyName, player.position)
	end
end
function playerClass:Despawn()
	local super = entityClass.Despawn
	super(self)
	broadcasters.despawn:Broadcast({ sourcePlayer = self })
end

function playerClass:Kick(reason)
	self.logger:Info("Kicking player for reason: " .. reason)
	local kickPacket = self.connection.protocol:PacketFromName("Disconnect")
	if kickPacket == nil then
		self.logger:Error("Disconnect packet not found")
		self:Remove()
		return
	end
	kickPacket.sender(self.connection, reason)
	self:Remove()
end

function playerClass:Remove()
	if self.removed then
		return
	end
	local super = entityClass.Remove
	super(self)
	playerRegistry:UnregisterEntity(self.id)
	self.connection:close()
	self.logger:Info("Player removed")
end

function playerClass:Chat(message)
	chat:Broadcast(message, nil, { sourcePlayer = self })
end

function playerClass:LoadWorld(world)
	local super = entityClass.LoadWorld
	super(self, world)
	if not (self.connection and self.connection.protocol) then
		error(self.logger:FormatErr("Connection or protocol not set"))
	end
	self.logger:Debug("Loading world")
	self.logger:Debug("Sending level initialize")
	local levelInitialize = self.connection.protocol:PacketFromName("LevelInitialize")
	if levelInitialize == nil then
		error(self.logger:FormatErr("LevelInitialize packet not found"))
		return
	end
	local initializeSender = levelInitialize.sender
	initializeSender(self.connection)
	local worldData = world:Pack(self.connection.protocol)
	local size = #worldData
	local chunkSize = 1024
	local chunks = math.ceil(size / chunkSize)
	local levelDataChunk = self.connection.protocol:PacketFromName("LevelDataChunk")
	if levelDataChunk == nil then
		error(self.logger:FormatErr("LevelDataChunk packet not found"))
		return
	end
	local dataChunkSender = levelDataChunk.sender
	self.logger:Debug("Sending level data")
	for i = 1, chunks do
		local chunk = worldData:sub((i - 1) * chunkSize + 1, i * chunkSize)
		dataChunkSender(self.connection, chunk, (math.floor(i / chunks)) * 100)
	end
	self.logger:Debug("Sending level finalize")
	local levelFinalize = self.connection.protocol:PacketFromName("LevelFinalize")
	if levelFinalize == nil then
		error(self.logger:FormatErr("LevelFinalize packet not found"))
		return
	end
	local finalizeSender = levelFinalize.sender
	finalizeSender(self.connection, world.size)
	self:MoveTo(world.spawn, true)
	self:Spawn()
end

return playerClass
