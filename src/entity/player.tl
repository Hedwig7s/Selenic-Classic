local require = require("customrequire")
local class = require("utility.class")
local type _ = require("entity.types")
local EntityPosition = require("datatypes.entityposition")
local entityClass = require("entity.entity")
local logger = require("utility.logging")

local players = {}

local playerClass = class("Player", {
    singleton = false,
    extends = entityClass,
    constructor = function(self:Instance, connection:Connection, name:string)
        local self = self as Player
        self.name = name
        self.fancyName = name -- TODO: Add fancy name
        self.connection = connection
        self.logger = logger.new("Player "..self.name)
        players[self.id] = self
    end,
    values = {
        MoveTo = function(self:Player, position:EntityPosition)
            local super = (entityClass.__values__ as Entity).MoveTo
            super(self as Entity, position)
            -- Add replication code
        end,
        Spawn = function(self:Player, position:EntityPosition)
            local super = (entityClass.__values__ as Entity).Spawn
            super(self as Entity)
            -- Add replication code
        end,
        LoadWorld = function(self:Player, world:World)
            local super = (entityClass.__values__ as Entity).LoadWorld
            super(self as Entity, world)
            if not (self.connection and self.connection.protocol) then
                self.logger:Error("Connection or protocol not set")
            end
            self.logger:Debug("Loading world")
            self.logger:Debug("Sending level initialize")
            local levelInitialize: Packet = self.connection.protocol:PacketFromName("LevelInitialize")
            if levelInitialize is nil then
                self.logger:Error("LevelInitialize packet not found")
                return
            end
            levelInitialize.sender(self.connection.protocol, self.connection)
            local worldData = world:Pack(self.connection.protocol)
            local size = #worldData
            local chunkSize = 1024
            local chunks = math.ceil(size / chunkSize)
            local levelDataChunk: Packet = self.connection.protocol:PacketFromName("LevelDataChunk")
            if levelDataChunk is nil then
                self.logger:Error("LevelDataChunk packet not found")
                return
            end
            self.logger:Debug("Sending level data")
            for i = 1, chunks do
                local chunk = worldData:sub((i - 1) * chunkSize + 1, i * chunkSize)
                levelDataChunk.sender(self.connection.protocol, self.connection, chunk, (i // chunks) * 100)
            end
            self.logger:Debug("Sending level finalize")
            local levelFinalize: Packet = self.connection.protocol:PacketFromName("LevelFinalize")
            if levelFinalize is nil then
                self.logger:Error("LevelFinalize packet not found")
                return
            end
            levelFinalize.sender(self.connection.protocol, self.connection, world.size.X, world.size.Y, world.size.Z)
        end
    }
})

return playerClass