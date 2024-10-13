local require = require("customrequire")
local type uv = require("uv")
local type Logger = require("utility.logging")
global type Protocol
global type Packet
local type class = require("middleclass")

global type Player
global type WorldManager

local record ServerModule
    record Server
        initialize: function(self:Server, host:string, port:integer)
        new: function(self:Server, host:string, port:integer): Server
        static: table
        isSubclassOf: function(self: Server, other:class.Class): boolean
        include: function(self: Server, ...:table): Server
        subclassed: function(self: Server, other:class.Class)
        allocate: function(self: Server): table
        isInstanceOf: function(self: Server, class: class.Class): boolean
        subclass: function(self:Server,name:string):  Server
        host: string
        port: integer
        socket: uv.Tcp
        worlds: WorldManager
        handleConnect: function(self:Server, err?: string)
        initialized: boolean
        logger: Logger
        init: function(self:Server)
        close: function(self:Server)
    end 
    record Connection
        initialize: function(self:Connection, socket:uv.Tcp)
        new: function(self:Connection, socket:uv.Tcp): Connection
        static: table
        isSubclassOf: function(self: Connection, other:class.Class): boolean
        include: function(self: Connection, ...:table): Connection
        subclassed: function(self: Connection, other:class.Class)
        allocate: function(self: Connection): table
        isInstanceOf: function(self: Connection, class: class.Class): boolean
        subclass: function(self:Connection,name:string):  Connection
        socket: uv.Tcp
        closed: boolean
        write: function(self:Connection, data:string)
        protocol: Protocol
        id: integer
        handlePacket: function(self:Connection, packet:Packet, data:string)
        init: function(self:Connection)
        logger: Logger
        player: Player
        initialized: boolean
        close: function(self:Connection)
    end
end

return ServerModule