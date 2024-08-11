---@class PlayerModule
local module = {}

-- Lazy load table and function
local lazyModules = {}

local function lazyLoad(moduleName)
    if not lazyModules[moduleName] then
        lazyModules[moduleName] = require(moduleName)
    end
    return lazyModules[moduleName]
end

---@class Player
---@field connection Connection
---@field position Position
---@field world World
---@field name string
---@field id number
---@field removed boolean
local Player = {}
Player.__index = Player

---@type table<string, Player>
local playersByName = {}
---@type table<number, Player>
local players = {}
setmetatable(players, {
    __newindex = function(self, key, value)
        rawset(self, key, value)
        if value and type(value) == "table" and value.name then
            playersByName[value.name] = value
        end
    end
})

---Spawns the player in a world. Should only be called on the player's first spawn in the world
---@param player Player?
function Player:Spawn(player)
    local packets = lazyLoad("./packets")
    if player and (self.world ~= player.world or player.id == self.id) then
        return
    end
    local position = self.position
    local function criteria(connection)
        return connection.player and connection.player.world == self.world
    end
    packets.ServerPackets.SpawnPlayer(self.id, self.name, position.x, position.y, position.z, position.yaw, position.pitch, criteria, player and player.connection or nil)
end

---Loads player into a world
---@param world World
function Player:LoadWorld(world)
    self.world = world
    local packets = lazyLoad("./packets")
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
    self:MoveTo(world.spawn, true)
    self:Spawn()
    for _, player in pairs(players) do
        player:Spawn(self)
    end
end

---Moves the player to a specified position
---@param position Position
---@param skipReplication boolean?
function Player:MoveTo(position, skipReplication, skipSelf)
    skipReplication = skipReplication or false
    self.position.x = position.x or self.position.x
    self.position.y = position.y or self.position.y
    self.position.z = position.z or self.position.z
    self.position.yaw = position.yaw or self.position.yaw
    self.position.pitch = position.pitch or self.position.pitch
    if not skipReplication then
        local packets = lazyLoad("./packets")
        local function criteria(connection)
            return connection.player and connection.player.world == self.world
        end
        packets.ServerPackets.SetPositionAndOrientation(self.id, self.position.x, self.position.y, self.position.z, self.position.yaw, self.position.pitch, criteria, skipSelf or false)
    end
end

---Despawns the player from the world
---@param player Player?
function Player:Despawn(player)
    local packets = lazyLoad("./packets")
    local success, err = pcall(packets.ServerPackets.DespawnPlayer,self.id, player and player.connection or nil)
    if not success then
        print(err)
    end
end

function Player:Remove()
    self:Despawn()
    players[self.id] = nil
    playersByName[self.name] = nil
    self.removed = true
end

function Player:Kick(reason)
    local packets = lazyLoad("./packets")
    pcall(packets.ServerPackets.DisconnectPlayer,self.connection, reason)
    self:Remove()
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
    self.position = {
        x = 0,
        y = 0,
        z = 0,
        yaw = 0,
        pitch = 0
    }
    self.world = nil
    self.name = name
    self.removed = false
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