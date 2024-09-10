local require = require("customrequire")
local type uv = require("uv")
local type Logger = require("utility.logging")
local type _ = require("networking.protocol.protocol")

global type Player

global record Server 
    initialize: function(self:Server, host:string, port:integer)
    new: function(self:Server, host:string, port:integer): Server
    extend: function(self:Server):  Server
    host: string
    port: integer
    socket: uv.Tcp
    handleConnect: function(self:Server, err: string|nil)
    initialized: boolean
    logger: Logger
    init: function(self:Server)
end

global record Connection
    initialize: function(self:Connection, socket:uv.Tcp)
    new: function(self:Connection, socket:uv.Tcp): Connection
    extend: function(self:Connection):  Connection
    socket: uv.Tcp
    closed: boolean
    readRoutine: thread
    write: function(self:Connection, data:string)
    protocol: Protocol
    id: integer
    handlePacket: function(self:Connection, packet:Packet, data:string)
    init: function(self:Connection)
    logger: Logger
    player: Player
    initialized: boolean
    Close: function(self:Connection)
end