local require = require("customrequire")
local core = require("core")
local protocolImpl = require("networking.protocol.protocol")
local packetUtility = require("networking.packetutility")
local serverConfig = require("data.config.serverconfig")
local playerClass = require("entity.player")
local playerRegistry = require("entity.playerregistry")
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
            connection.logger:Info("Player joined with username "..username)
            connection.logger:Debug("Received identification packet")
            connection.logger:Debug("Username: "..username)
            connection.logger:Debug("Protocol: "..tostring(protVersion))
            connection.logger:Debug("Supports CPE: "..tostring(CPE))
            packet.sender(protocol, connection, serverConfig:get("server.serverName"), serverConfig:get("server.motd"))
            connection.logger:Debug("Creating player")
            local disconnectPacket = protocol:PacketFromName("Disconnect")
            if disconnectPacket is nil then
                connection.logger:Error("Disconnect packet not found")
                return
            end
            if playerRegistry:GetEntityByName(username) then
                connection.logger:Warn("Player with this username already exists")
                disconnectPacket.sender(protocol, connection, "Username already in use")
                return
            end
            if #playerRegistry:GetEntities() >= serverConfig:get("server.maxPlayers") as integer then
                disconnectPacket.sender(protocol, connection, "Server is full")
                connection.logger:Warn("Server is full")
                return
            end
            local player:Player = playerClass:new(name as string, connection) as Player
            connection.player = player
            connection.logger:Debug("Player created, loading world")
            local worldName = serverConfig:get("server.defaultWorld")
            if not (worldName is string) then
                disconnectPacket.sender(protocol, connection, "Could not find world")
                connection.logger:Error("Default world not set")
                return
            end
            local world = worlds:getWorld(worldName)
            if not (world is World) then
                disconnectPacket.sender(protocol, connection, "Could not find world")
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
        sender = function(protocol:Protocol, connection:Connection, _:integer, position:Vector3, block:Block)
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
            packetUtility.sendPacket(connection,packet.format, packet.id, entityId, name, packetUtility.formatEntityPosition(position))
        end,
    },
    [0x08] = {
        format = ">BbHHHBB",
        size = 10,
        id = 0x08,
        name = "PositionAndOrientation",
        sender = function(protocol:Protocol, connection:Connection, entityId:integer, position:EntityPosition)
            local packet = protocol:PacketFromName("PositionAndOrientation") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, entityId, packetUtility.formatEntityPosition(position))
        end,
        receiver = function(protocol:Protocol, connection:Connection, data:string)
            local packet = protocol:PacketFromName("PositionAndOrientation") as Packet
            local _, entityId, x, y, z, yaw, pitch = packetUtility.parsePacket(packet.format, data)
            x, y, z = packetUtility.fromFixedPoint(x as number, y as number, z as number)
            local player = connection.player
            if not (player is Player) then
                connection.logger:Error("Player not set")
                return
            end
            player:MoveTo(EntityPosition.new(x as number, y as number, z as number, yaw as number, pitch as number))
        end
    }, 
    [0x09] = {
        format = ">BbBBBBB",
        size = 7,
        id = 0x09,
        name = "PositionAndOrientationUpdate",
        sender = function(protocol:Protocol, connection:Connection, entityId:integer, position:EntityPosition)
            local packet = protocol:PacketFromName("PositionAndOrientationUpdate") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, entityId, packetUtility.formatEntityPosition(position))
        end,
    },
    [0x0A] = {
        format = ">BbBBB",
        size = 5,
        id = 0x0A,
        name = "PositionUpdate",
        sender = function(protocol:Protocol, connection:Connection, entityId:integer, position:EntityPosition)
            local packet = protocol:PacketFromName("PositionUpdate") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, entityId, packetUtility.toFixedPoint(position.X, position.Y, position.Z))
        end,
    },
    [0x0B] = {
        format = ">BbBB",
        size = 4,
        id = 0x0B,
        name = "OrientationUpdate",
        sender = function(protocol:Protocol, connection:Connection, entityId:integer, position:EntityPosition)
            local packet = protocol:PacketFromName("OrientationUpdate") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, entityId, position.yaw, position.pitch)
        end,
    },
    [0x0C] = {
        format = ">Bb",
        size = 2,
        id = 0x0C,
        name = "DespawnPlayer",
        sender = function(protocol:Protocol, connection:Connection, entityId:integer)
            local packet = protocol:PacketFromName("DespawnPlayer") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, entityId)
        end,
    },
    [0x0D] = {
        format = ">Bbc64",
        size = 2,
        id = 0x0D,
        name = "Message",
        sender = function(protocol:Protocol, connection:Connection, id:integer, message:string)
            local packet = protocol:PacketFromName("Message") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, id, message)
        end,
    },
    [0x0E] = {
        format = ">Bc64",
        size = 65,
        id = 0x0E,
        name = "Disconnect",
        sender = function(protocol:Protocol, connection:Connection, reason:string)
            local packet = protocol:PacketFromName("Disconnect") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, reason)
        end,
    },
    [0x0F] = {
        format = ">BB",
        size = 2,
        id = 0x0F,
        name = "UpdateUserType",
        sender = function(protocol:Protocol, connection:Connection, userType:boolean)
            local packet = protocol:PacketFromName("UpdateUserType") as Packet
            packetUtility.sendPacket(connection,packet.format, packet.id, userType and 0x64 or 0x00)
        end,
    }
}
protocolClass.Meta = {
    Version = 7
}

return protocolClass