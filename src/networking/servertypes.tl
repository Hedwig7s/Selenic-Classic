local require = require("customrequire")
local type uv = require("uv")
local type _ = require("utility.class")
local type _ = require("utility.logging")
local type _ = require("networking.protocol.protocol")
global record Server 
    __class__: BaseClass
    host: string
    port: integer
    socket: uv.Tcp
    handleConnect: function(self:Server, err: any)
    initialized: boolean
    logger: Logger
    init: function(self:Server)
end

global record Connection
    __class__: BaseClass
    socket: uv.Tcp
    closed: boolean
    readRoutine: thread
    write: function(self:Connection, data:string)
    protocol: Protocol
    id: integer
    handlePacket: function(self:Connection, packet:Packet, data:string)
    init: function(self:Connection)
    logger: Logger
    initialized: boolean
end