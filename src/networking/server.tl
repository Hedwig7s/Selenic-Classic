local require = require("customrequire")
local class = require("class")
local loggerClass = require("logging")
local uv = require("uv")
local timer = require("timer")

local connections: {integer:Connection} = {}
local connectionCount = 0

local type _ = require("networking.protocol.protocol")

local protocols:{string|number: Protocol} = {
    
}

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
    protocol: Protocol
    id: integer
    handlePacket: function(self:Connection, packet:ClientPacket, data:string)
    init: function(self:Connection)
    logger: Logger
    initialized: boolean
end

local connectionClass = class("Connection", {
    singleton = false,
    constructor = function(self:Instance, _:BaseClass|nil, socket:uv.Tcp)
        local self = self as Connection
        self.socket = socket
        self.closed = false
        self.initialized = false
        self.logger = loggerClass.new("Connection "..connectionCount)
        connections[connectionCount] = self
        self.id = connectionCount
        connectionCount = connectionCount + 1
    end,
    values = {
        handlePacket = function(self:Connection, packet:ClientPacket, data:string)

        end,
        init = function(self:Connection)
            if self.initialized then
                return
            end
            self.initialized = true
            self.logger:Debug("Client connected")
            local buffer:{string} = {}
            local function read_buffer(bytes:integer, leaveData:boolean): string
                local data = table.concat(buffer)
                local size = #data
                bytes = bytes or size
            
                while bytes > size and not self.closed do
                    timer.sleep(2)
                    data = table.concat(buffer)
                    size = #data
                end
            
                if bytes == size and not leaveData then
                    buffer = {}
                elseif not leaveData then
                    buffer = {data:sub(bytes + 1)}
                end
            
                return data:sub(1, bytes)
            end

            self.socket:read_start(function(err:string|nil, data:string|nil)
                if err then
                    self.logger:Error("Failed to read TCP data: " .. err, true)
                    self.closed = true
                    pcall(self.socket.close, self.socket)
                    return
                end
                if data and #data > 0 then
                    table.insert(buffer,data)
                end
            end)

            self.readRoutine = coroutine.create(function()
                while not self.closed do
                    timer.sleep(1)
                    local data = read_buffer(1)
                    if #data == 1 then
                        local id = string.unpack(">B", data) as integer
                        if id == 0x00 then
                            local protVersion = string.unpack(">B", read_buffer(1,true)) as integer
                            if protVersion < 2 or protVersion > 7 then
                                protVersion = 1 -- c0.0.15a
                            end
                            local protocol = protocols[protVersion]
                            if not protocol then
                                self.logger:Warn("Unsupported protocol version: " .. protVersion)
                            end
                            self.protocol = protocol
                        end
                        if self.protocol then
                            local packet = self.protocol.ClientPackets[id]
                            if not packet then 
                                self.logger:Warn("Received unknown packet id: " .. id)
                            else
                                local size = packet.size
                                data = data..read_buffer(size-1)
                                self:handlePacket(packet, data)
                            end
                        end
                    end
                end
            end)
            coroutine.resume(self.readRoutine)
        end,
    }
})

local serverClass = class("Server", {
    singleton = true,
    constructor = function(self:Instance, _:BaseClass|nil, host:string, port:integer)
        assert(self )
        local self = self as Server
        self.host = host
        self.port = port
        self.logger = loggerClass.new("Server")
        self.initialized = false
    end,
    values = {
        handleConnect = function(self:Server, err:string|nil)
            assert(not err, err)
            local client = uv.new_tcp()
            self.socket:accept(client)
            local connection = connectionClass(client) as Connection
            connection:init()
        end,
        init = function(self:Server)
            if self.initialized then
                return
            end
            self.initialized = true
            self.socket = uv.new_tcp() 
            self.socket:bind(self.host, self.port)
            self.socket:listen(128, function(err:string|nil)
                self:handleConnect(err)
            end)
            self.logger:Info("Started")
        end,
    }
})

return serverClass