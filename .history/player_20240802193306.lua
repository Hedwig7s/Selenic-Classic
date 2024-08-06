local module = {}

local worlds = require("./worlds")
local config = require("./config")

local Player = {}
Player.__index = Player

function Player:LoadWorld(world)
    self.world = world
    local packets = require("./packets")
    print("Packing world")
    local packed = world:Pack()
    ServerPackets.LevelInitialize(write)
    print("Initialising level")
    local length = #packed
    local chunkSize = 1024
    local chunks = math.ceil(length/chunkSize)
    print("Sending level data")
    for i = 1, chunks do
        local chunk = packed:sub((i-1)*chunkSize+1, i*chunkSize)
        ServerPackets.LevelDataChunk(write, #chunk, chunk, math.floor(i/chunks*100))
    end
    print("Finalising level")
    ServerPackets.LevelFinalize(write, world.size)
end

function Player:MoveTo(x, y, z)
    self.x = x
    self.y = y
    self.z = z
end

function Player.new(connection)
    local self = setmetatable({}, Player)
    self.connection = connection
    self.x = 0
    self.y = 0
    self.z = 0
    self.yaw = 0
    self.pitch = 0
    self.world = nil
    return self
end

return module