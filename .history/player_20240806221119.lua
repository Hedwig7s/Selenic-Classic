--@class PlayerModule
local module = {}

local worlds = require("./worlds")
local config = require("./config")

---@class Player
---@field connection Connection
---@field x number
---@field y number
---@field z number
---@field yaw number
---@field pitch number
---@field world World
---@field name string
local Player = {}
Player.__index = Player

---Spawns the player in a world. Should only be called on the player's first spawn in the world
function Player:Spawn()
    local packets = require("./packets")
    packets.ServerPackets.SpawnPlayer(self.connection.id, self.name, self.x, self.y, self.z, self.yaw, self.pitch)
end

---Loads player into a world
function Player:LoadWorld(world)
    self.world = world
    local packets = require("./packets")
    print("Packing world")
    local packed = world:Pack()
    packets.ServerPackets.LevelInitialize(self.connection)
    print("Initialising level")
    local length = #packed
    local chunkSize = 1024
    local chunks = math.ceil(length/chunkSize)
    print("Sending level data")
    for i = 1, chunks do
        local chunk = packed:sub((i-1)*chunkSize+1, i*chunkSize)
        packets.ServerPackets.LevelDataChunk(self.connection, #chunk, chunk, math.floor(i/chunks*100))
    end
    print("Finalising level")
    packets.ServerPackets.LevelFinalize(self.connection, world.size)
    self:Spawn()
    self:MoveTo(world.spawn.x, world.spawn.y, world.spawn.z)
end

function Player:MoveTo(x, y, z)
    self.x = x
    self.y = y
    self.z = z
end

function Player.new(connection, name)
    local self = setmetatable({}, Player)
    self.connection = connection
    self.x = 0
    self.y = 0
    self.z = 0
    self.yaw = 0
    self.pitch = 0
    self.world = nil
    self.name = name
    return self
end

module.Player = Player

return module