local require = require("customrequire")
local Logger = require("utility.logging")
local uv = require("uv")
local timer = require("timer")
local core = require("core")
local Object = core.Object

local type ServerModule = require("networking.servertypes")
local type Server = ServerModule.Server
local type Connection = ServerModule.Connection

local connections: {integer:Connection} = {}
local connectionCount = 0

local type _ = require("networking.protocol.protocol")

local protocols:{integer: Protocol|nil} = {
    [7] = require("networking.protocol.protocol7")
}

local connectionClass = Object:extend() as Connection
function connectionClass:initialize(socket:uv.Tcp)
    self.socket = socket
    self.closed = false
    self.initialized = false
    self.write = function(self:Connection,data:string): any, string
        if self.closed then
            return
        end
        return self.socket:write(data)
    end
    self.logger = Logger.new("Connection "..connectionCount)
    connections[connectionCount] = self
    self.id = connectionCount
    connectionCount = connectionCount + 1
end
function connectionClass:handlePacket(packet:Packet, data:string)
    local receiver = packet.receiver
    if receiver is ClientReceiver then
        receiver(self, data) -- Error handling handled by the routine loop
    end
end
function connectionClass:Close()
    if self.player and not self.player.removed then  -- Should be safe since removed is set before Close is called
        self.player:Remove()
    else
        self.closed = true
        pcall(self.socket.close, self.socket)
    end
end
function connectionClass:init()
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
            timer.sleep(5)
            data = table.concat(buffer)
            size = #data
        end
        if self.closed then return nil end
    
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
            self:Close()
            return
        end
        if data and #data > 0 then
            table.insert(buffer,data)
        elseif not data then
            if self.player then
                self.player:Remove()
            end
            self.logger:Debug("Client disconnected")
            self:Close()
        end
    end)
    timer.setTimeout(5000, function()
        if not self.player then
            self.logger:Warn("Client did not log in within 5 seconds")
            self:Close()
        end
    end)
    self.readRoutine = coroutine.create(function()
        local function process()
            local data = read_buffer(1)
            if data and #data == 1 then
                local id = string.unpack(">B", data) as integer
                if id == 0x00 then
                    local protVerString = read_buffer(1,true)
                    if not protVerString then
                        return
                    end
                    local protVersion = string.unpack(">B", protVerString) as integer
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
                    local packet = self.protocol.Packets[id]
                    if not packet then 
                        self.logger:Error("Received unknown packet id: " .. id, true)
                        if self.player then
                            self.player:Kick("Unknown packet id: " .. id)
                        else
                            self:Close()
                        end
                    else
                        local size = packet.size
                        data = data..read_buffer(size-1)
                        self:handlePacket(packet, data)
                    end
                end
            end
        end
        while not self.closed do
            timer.sleep(5)
            local co = coroutine.create(process)
            local success, err = coroutine.resume(co)
            if not success then
                self.logger:Error("Error processing packet:\n"..(err as string).."\n"..debug.traceback(co):gsub("\n", "\n\t"), true)
            end
        end
    end)
    coroutine.resume(self.readRoutine)
end


local serverClass = Object:extend() as Server

function serverClass:initialize(host:string, port:integer)
    assert(self)
    local self = self as Server
    self.host = host
    self.port = port
    self.logger = Logger.new("Server")
    self.initialized = false
end
function serverClass:handleConnect(err:string|nil)
    assert(not err, err)
    local client = uv.new_tcp()
    self.socket:accept(client)
    local connection = connectionClass:new(client)
    connection:init()
end
function serverClass:init()
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
end
return serverClass