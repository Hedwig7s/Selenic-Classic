local module = {}

local server = require("../server")
local packetutil = require("./packetutil")
local criterias = require("../criterias")

local formatStrings = {
    ExtInfo = ">Bc64H",
    ExtEntry = ">Bc64I4",
    ClickDistance = ">BH",
    HeldBlock = ">BBB",
    ExtAddPlayerName = ">BHc64c64c64B",
    ExtAddEntity2 = ">Bbc64c64HHHBB",
    ExtRemovePlayerName = ">BH",
}

local extensions = {}
module.Extensions = extensions
local extensionsCount = 0

---@param connection Connection
local function serverExtInfo(connection)
    connection.write(string.pack(formatStrings.ExtInfo, 0x10, packetutil.formatString(server.info.Software .. " " .. server.info.Version),
        extensionsCount))
    for name, extension in pairs(extensions) do
        module.ServerPackets.ExtEntry(connection, name, extension.version)
    end
    return true
end

local function serverExtEntry(connection, name, version)
    return connection.write(string.pack(formatStrings.ExtEntry, 0x11, packetutil.formatString(name), version))
end


local ServerPackets = {
    ExtInfo = serverExtInfo,
    ExtEntry = serverExtEntry,
}

module.ServerPackets = ServerPackets

---@param data string
---@param connection Connection
local function clientExtInfo(data, connection)
    local _, client, extensionCount = string.unpack(formatStrings.ExtInfo, data)
    if not connection.player then
        error("Player not set")
    end
    local player = connection.player
    player.client = packetutil.unformatString(client)
    player.extensionCount = extensionCount
end

local function clientExtEntry(data, connection)
    local _, name, version = string.unpack(formatStrings.ExtEntry, data)
    name = packetutil.unformatString(name)
    local player = connection.player
    if not player then
        error("Player not set")
    end
    player.CPE[name] = version
    if #player.CPE >= player.extensionCount then
        player.identifiedCPE = true
    end
end

local ClientPackets = {
    [0x10] = clientExtInfo,
    [0x11] = clientExtEntry,
}

module.ClientPackets = ClientPackets


---@param name string
---@param version number
---@param serverFunctions table<function>|nil|fun(connection: Connection, ...):boolean
---@param clientFunctions table<function>|fun(data: string, connection: Connection)?
local function registerExtension(name, version, serverFunctions, clientFunctions)
    extensions[name] = {
        version = version
    }
    extensionsCount = extensionsCount + 1
    if serverFunctions and type(serverFunctions) == "function" then
        ServerPackets[name] = serverFunctions
    elseif serverFunctions and type(serverFunctions) == "table" then
        ServerPackets[name] = serverFunctions
    end
    if clientFunctions and type(clientFunctions) == "function" then
        ClientPackets[name] = clientFunctions
    elseif clientFunctions and type(clientFunctions) == "table" then
        ClientPackets[name] = clientFunctions
    end
end

registerExtension("ClickDistance", 1, function(connection, distance)
    if not connection.player then
        return false
    end
    connection.player.clickDistance = distance
    return connection.write(string.pack(formatStrings.ClickDistance, 0x12, distance))
end)

registerExtension("HeldBlock", 1, function(connection, block, allowChange)
    if not connection.player then
        return false
    end
    return connection.write(string.pack(formatStrings.HeldBlock, 0x14, block, allowChange and 1 or 0))
end)

registerExtension("ExtPlayerList", 2, {
    ExtAddPlayerName = packetutil.multiPlayerWrapper(function (connection, id, name, group, list, rank)
        return connection.write(string.pack(formatStrings.ExtAddPlayerName, 0x16, id, packetutil.formatString(name), packetutil.formatString(group), packetutil.formatString(list), rank))
    end, criterias.hasExtension("ExtPlayerList"), true),
    ExtRemovePlayerName = packetutil.multiPlayerWrapper(function (connection, id)
        return connection.write(string.pack(formatStrings.ExtRemovePlayerName, 0x18, id))
    end, criterias.hasExtension("ExtPlayerList"),true),
    ExtAddEntity2 = function (connection, id, name, skinName, x, y, z, yaw, pitch)
        name, skinName = packetutil.formatString(name), packetutil.formatString(skinName)
        local dataProvider = function(id, x, y, z, yaw, pitch)
            return string.pack(formatStrings.ExtAddEntity2, 0x21, id, name, skinName, x, y, z, yaw, pitch)
        end
        return packetutil.baseMovementPacket(connection, id, x, y, z, yaw, pitch, dataProvider, false) 
    end
})


return module
