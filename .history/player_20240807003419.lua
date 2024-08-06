---@class PlayerModule
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
---@field id number
local Player = {}
Player.__index = Player

---@type table<string, Player>
local playersByName = {}
---@type table<number, Player>
local players = {
    __newindex = function(self, key, value)
        rawset(self, key, value)
        playersByName[value.name] = value
    end
}

---Spawns the player in a world. Should only be called on the player's first spawn in the world
function Player:Spawn()
    local packets = require("./packets")
    packets.ServerPackets.SpawnPlayer(self.connection.id, self.name, self.x, self.y, self.z, self.yaw, self.pitch)
end

---Loads player into a world
---@param world World
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
    for _, player in pairs(players) do
        if player.world == world and player.id ~= self.id then
            packets.ServerPackets.SpawnPlayer(player.connection.id, player.name, player.x, player.y, player.z, player.yaw, player.pitch, self.connection)
        end
    end
end

---Moves the player to a specified position
---@param x number
---@param y number
---@param z number
function Player:MoveTo(x, y, z)
    self.x = x
    self.y = y
    self.z = z
end

---Creates new player
---@param connection Connection
---@param name string
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
    local id = -1
    repeat id = id + 1 until not players[id] or id > 255
    if id > 255 then
        error("Too many players!")
    end
    self.id = id
    players[self.id] = self
    return self
end

module.Player = Player

---Get player by id
---@param id number
---@return Player?
function module:GetPlayerById(id)
    return players[id]
end

---Get player by username
---@param name string
---@return Player?
function module:GetPlayerByName(name)
    return playersByName[name]
end

return module