local require = require("customrequire")
local Logger = require("utility.logging")
local uv = require("uv")
local timer = require("timer")
local class = require("middleclass")

local connections = {}
local connectionCount = 0

local _ = require("networking.protocol.protocol")

local protocols = {
	[7] = require("networking.protocol.protocol7"),
}

local connectionClass = class("Connection")
function connectionClass:initialize(socket)
	self.socket = socket
	self.closed = false
	self.initialized = false
	self.write = function(self, data)
		if self.closed then
			return
		end
		return self.socket:write(data)
	end
	self.logger = Logger.new("Connection " .. connectionCount)
	connections[connectionCount] = self
	self.id = connectionCount
	connectionCount = connectionCount + 1
end
function connectionClass:handlePacket(packet, data)
	local receiver = packet.receiver
	receiver(self, data)
end
function connectionClass:close()
	if self.closed then
		return
	end
	if self.player and not self.player.removed then
		self.player:Remove()
	else
		self.closed = true
		pcall(self.socket.close, self.socket)
		connections[self.id] = nil
	end
end
function connectionClass:init()
	if self.initialized then
		return
	end
	self.initialized = true
	self.logger:Debug("Client connected")
	local buffer = {}
	local function read_buffer(bytes, leaveData)
		local data = table.concat(buffer)
		local size = #data
		bytes = bytes or size
		if size < bytes then
			bytes = size
		end

		if self.closed then
			return nil
		end

		if bytes == size and not leaveData then
			buffer = {}
		elseif not leaveData then
			buffer = { data:sub(bytes + 1) }
		end

		return data:sub(1, bytes), bytes
	end
	local function process()
		local data, read = read_buffer(1, true)
		if not data or read < 1 then
			return
		end
        local id = string.unpack(">B", data)
        if id == 0x00 then
            local protVerString, read = read_buffer(2, true)
            if not protVerString or read < 2 then
                return
            end
            local protVersion = string.unpack(">B", protVerString:sub(2, 2))
            if protVersion < 2 or protVersion > 7 then
                protVersion = 1
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
                self.logger:Error("Received unknown packet id: " .. id)
                if self.player then
                    self.player:Kick("Unknown packet id: " .. id)
                else
                    self:close()
                end
            else
                local size = packet.size
                local fullData, read = read_buffer(size)
                if read < size then
                    return
                end
                data = fullData
                self:handlePacket(packet, data)
            end
        end
		return true
	end
	self.socket:read_start(function(err, data)
		if err then
			self.logger:Error("Failed to read TCP data: " .. err)
			self:close()
			return
		end
		if data and #data > 0 then
			table.insert(buffer, data)
			local interval
			interval = timer.setInterval(5, function()
				local co = coroutine.create(process)
				local success, err = coroutine.resume(co)
				if not success then
					self.logger:Error(
						"Error processing packet:\n" .. tostring(err) .. "\n" .. debug.traceback(co):gsub("\n", "\n\t")
					)
					err = false
				end
				if not err then
					timer.clearInterval(interval)
				end
			end)
		elseif not data then
			self.logger:Debug("Client disconnected")
			self:close()
		end
	end)
	timer.setTimeout(5000, function()
		if not self.player then
			self.logger:Warn("Client did not log in within 5 seconds")
			self:close()
		end
	end)
end

local serverClass = class("Server")

function serverClass:initialize(host, port)
	assert(self)
	local self = self
	self.host = host
	self.port = port
	self.logger = Logger.new("Server")
	self.initialized = false
end
function serverClass:handleConnect(err)
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
	self.socket:listen(128, function(err)
		self:handleConnect(err)
	end)
	self.logger:Info("Started")
end
function serverClass:close()
	for _, connection in pairs(connections) do
		if connection.player then
			connection.player:Kick("Server shutting down")
		end
		connection:close()
	end
	self.socket:close()
	self.initialized = false
end
return serverClass
