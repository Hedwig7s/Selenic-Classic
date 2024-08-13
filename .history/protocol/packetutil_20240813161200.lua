local module = {}
local util = require("../util")


---Formats string to 64 characters with padding
---@param str string
---@return string
function module.formatString(str)
    return util.pad(str,64,"\32")
end

---Reverts packet padding on a string
---@param str string
---@return string
function module.unformatString(str)
    for i = #str,1,-1 do
        if str:sub(i,i) ~= "\32" then
            return str:sub(1,i)
        end
    end
    return ""
end

---Converts numbers to fixed point
---@param ... number
---@return number ...
function module.toFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, math.floor(v * 32))
    end
    return unpack(values) 
end

---Converts fixed point to numbers
---@param ... number
---@return number ...
function module.fromFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, v/32)
    end
    return unpack(values) 
end

---Sends packet about a specific player to all clients, substituting the target's id with -1 when sending to the target
---@param dataProvider fun(id:number):string
---@param targetId number
---@param connection Connection?
---@param errorHandler? fun(err:string)
---@param criteria? fun(connection:Connection):boolean
---@param skip? table<number, boolean>
---@return boolean, string?
function module.perPlayerPacket(dataProvider, targetId, errorHandler, criteria, skip, connection)
    local data = dataProvider(targetId)
    skip = skip or {}
    if connection then
        return connection.write(data)
    end
    for _, connection in pairs(connections) do
        local player = connection.player
        local passed do
            if criteria then
                passed = criteria(connection)
            else
                passed = true
            end
        end
        if player and not skip[player.id] and passed then
            local d = player.id == targetId and dataProvider(-1) or data
            local success, err = connection.write(d)
            if not success and errorHandler and err then
                errorHandler(err)
            end
        end
    end
end

return module