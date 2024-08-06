local module = {}

local worlds = require("./worlds")
local config = require("./config")

local Player = {}
Player.__index = Player

function Player:Spawn()
    local packets = require("./packets")
    packets.ServerPackets.SpawnPlayer(self.connection.id, self.name, self.x, self.y, self.z, self.yaw, self.pitch)
end
function Player:LoadWorld(world)
    self.world = world
    local packets = require("./packets")
    print("Packing world")
    local packed = world:Pack()
    local write = self.connection.write
    packets.ServerPackets.LevelInitialize(write)
    print("Initialising level")
    local length = #packed
    local chunkSize = 1024
    local chunks = math.ceil(length/chunkSize)
    print("Sending level data")
    for i = 1, chunks do
        local chunk = packed:sub((i-1)*chunkSize+1, i*chunkSize)
        packets.ServerPackets.LevelDataChunk(write, #chunk, chunk, math.floor(i/chunks*100))
    end
    print("Finalising level")
    packets.ServerPackets.LevelFinalize(write, world.size)
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

return module