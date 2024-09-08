local require = require("customrequire")
local Logger = require("utility.logging")
local uv = require("uv")
local timer = require("timer")
local core = require("core")
local Object = core.Object

local type _ = require("networking.servertypes")

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
        local co = coroutine.create(receiver)
        local success, err = coroutine.resume(co, self.protocol, self, data)
        if not success then
            self.logger:Error(("Error processing packet "..packet.name..":\n"..(err as string).."\n"..debug.traceback(co)):gsub("\n", "\n\t"), true)
        end
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
    local connectTime = os.time()
    self.readRoutine = coroutine.create(function()
        while not self.closed do
            timer.sleep(5)
            local data = read_buffer(1)
            local loggedIn = self.player and true or false
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
                    local packet = self.protocol.Packets[id]
                    if not packet then 
                        self.logger:Warn("Received unknown packet id: " .. id)
                    else
                        local size = packet.size
                        data = data..read_buffer(size-1)
                        self:handlePacket(packet, data)
                    end
                end
            end
            if not loggedIn and os.time() - connectTime > 5 then
                self.logger:Warn("Client did not log in within 5 seconds")
                self.closed = true
                pcall(self.socket.close, self.socket)
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