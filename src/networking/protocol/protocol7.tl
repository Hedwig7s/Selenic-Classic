local require = require("customrequire")
local core = require("core")
local protocolImpl = require("networking.protocol.protocol")
local packetUtility = require("networking.packetutility")
local serverConfig = require("data.config.serverconfig")
local playerClass = require("entity.player")
local worlds = require("data.worlds.worlds")
local blockModule = require("data.blocks")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local type _ = require("networking.servertypes")
local type _ = require("networking.protocol.protocol")

local protocolClass = protocolImpl:extend() 
protocolClass.Packets = {
    [0x00] = {
        format = ">BBc64c64B",
        size = 131,
        id = 0x00,
        name = "Identification",
        sender = function(protocol:Protocol, connection:Connection, name:string, motd:string)
            local packet = protocol:PacketFromName("Identification") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, protocol.Meta.Version, name, motd, 0x00)
        end,
        receiver = function(protocol:Protocol, connection:Connection, data:string)
            local packet = protocol:PacketFromName("Identification") as Packet
            local _, protVersion, name, verkey, CPEcode = packetUtility.parsePacket(packet.format, data)
            local verificationKey = tostring(verkey)
            local username = tostring(name)
            local CPE = CPEcode == 0x42
            connection.logger:Debug("Received identification packet")
            connection.logger:Debug("Username: "..username)
            connection.logger:Debug("Protocol: "..tostring(protVersion))
            connection.logger:Debug("Supports CPE: "..tostring(CPE))
            packet.sender(protocol, connection, serverConfig:get("server.serverName"), serverConfig:get("server.motd"))
            connection.logger:Debug("Creating player")
            local player:Player = playerClass:new(name as string, connection) as Player
            connection.player = player
            connection.logger:Debug("Player created, loading world")
            local worldName = serverConfig:get("server.defaultWorld")
            if not (worldName is string) then
                connection.logger:Error("Default world not set")
                return
            end
            local world = worlds:getWorld(worldName)
            if not (world is World) then
                connection.logger:Error("World not found")
                return
            end
            player:LoadWorld(world as World)
        end
    },
    [0x01] = {
        format = ">B",
        size = 1,
        id = 0x01,
        name = "Ping",
        sender = function(protocol:Protocol, connection:Connection)
            local packet = protocol:PacketFromName("Ping") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id)
        end,
    },
    [0x02] = {
        format = ">B",
        size = 1,
        id = 0x02,
        name = "LevelInitialize",
        sender = function(protocol:Protocol, connection:Connection)
            local packet = protocol:PacketFromName("LevelInitialize") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id)
        end,
    },
    [0x03] = {
        format = ">BHc1024B",
        size = 1028,
        id = 0x03,
        name = "LevelDataChunk",
        sender = function(protocol:Protocol, connection:Connection, levelData:string, percentage:integer)
            if #levelData > 1024 then
                connection.logger:Error("Level data chunk too large")
                return
            end
            local packet = protocol:PacketFromName("LevelDataChunk") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, #levelData, levelData..string.rep("\0", 1024-#levelData), percentage)
        end,
    },
    [0x04] = {
        format = ">BHHH",
        size = 7,
        id = 0x04,
        name = "LevelFinalize",
        sender = function(protocol:Protocol, connection:Connection, size:Vector3)
            local packet = protocol:PacketFromName("LevelFinalize") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, size.X, size.Y, size.Z)
        end,
    },
    [0x05] = {
        format = ">BHHHBB",
        size = 9,
        id = 0x05,
        name = "ClientSetBlock",
        receiver = function(protocol:Protocol, connection:Connection, data:string)
            local packet = protocol:PacketFromName("ClientSetBlock") as Packet
            local _, x, y, z, mode, block = packetUtility.parsePacket(packet.format, data) 

            local player = connection.player
            if not (player is Player) then
                connection.logger:Error("Player not set")
                return
            end
            local world = player.world
            if not (world is World) then
                connection.logger:Error("World not set")
                return
            end
            if mode == 0 then
                block = blockModule.BLOCK_IDS.AIR
            end
            world:SetBlock(Vector3.new(x as integer, y as integer, z as integer), block as Block, false, connection.player)
        end
    },
    [0x06] = {
        format = ">BHHHB",
        size = 9,
        id = 0x06,
        name = "ServerSetBlock",
        sender = function(protocol:Protocol, connection:Connection, position:Vector3, block:Block)
            local packet = protocol:PacketFromName("ServerSetBlock") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, position.X, position.Y, position.Z, block)
        end,
    },
    [0x07] = {
        format = ">Bbc64HHHBB",
        size = 74,
        id = 0x07,
        name = "SpawnPlayer",
        sender = function(protocol:Protocol, connection:Connection, entityId:integer, name:string, position:EntityPosition)
            local packet = protocol:PacketFromName("SpawnPlayer") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, entityId, name, position.X, position.Y, position.Z, position.yaw, position.pitch)
        end,
    }
}
protocolClass.Meta = {
    Version = 7
}

return protocolClass