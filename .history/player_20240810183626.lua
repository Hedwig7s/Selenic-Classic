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
local players = {}
setmetatable(players, {
    __newindex = function(self, key, value)
        rawset(self, key, value)
        playersByName[value.name] = value
    end
})


---Spawns the player in a world. Should only be called on the player's first spawn in the world
---@param player Player?
function Player:Spawn(player)
    local packets = require("./packets")
    if player and (self.world ~= player.world or player.id == self.id) then
        return
    end
    packets.ServerPackets.SpawnPlayer(self.connection.id, self.name, self.x, self.y, self.z, self.yaw, self.pitch, player and player.connection or nil)
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
    require("inspect")(world.spawn)
    self:MoveTo(world.spawn.x, world.spawn.y, world.spawn.z, true)
    self:Spawn()
    for _, player in pairs(players) do
        player:Spawn(self)
    end
end

---Moves the player to a specified position
---@param x number
---@param y number
---@param z number
function Player:MoveTo(x, y, z, skipReplication)
    skipReplication = skipReplication or false
    self.x = x
    self.y = y
    self.z = z
end

---Creates new player
---@param connection Connection
---@param name string
---@return Player?, string?
function Player.new(connection, name)
    if module:GetPlayerByName(name) then
        local err = "Player with name "..name.." already exists"
        print(err)
        return nil, err
    end
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
        local err = "Too many players!"
        print(err)
        return nil, err
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