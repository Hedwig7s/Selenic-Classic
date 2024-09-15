local module = {}
local require = require("customrequire")
local type ServerModule = require("networking.servertypes")
local type Connection = ServerModule.Connection
local type EntityPosition = require("datatypes.entityposition")

function module.sendPacket(connection:Connection, format:string, ...:any): string
    local data = {...}
    for i, v in ipairs(data) do
        if v is string then
            local str = v as string
            data[i] = str..string.rep("\32", math.max(64 - #str, 0))
        end
    end
    return connection:write(string.pack(format, table.unpack(data)))
end

function module.parsePacket(format:string, data:string): any...
    local unpackedData: {integer: any} = {string.unpack(format, data)}
    for i, v in ipairs(unpackedData) do
        if v is string then
            local str = v as string
            for j = #v,1,-1 do
                if str:sub(j,j) ~= "\32" then
                    str = str:sub(1,j)
                    break
                end
            end
            unpackedData[i] = str
        end
    end
    return table.unpack(unpackedData)
end

function module.toFixedPoint(...:number):integer...
    local data = {...}
    local fixedData: {integer} = {}
    for _, v in ipairs(data) do
        table.insert(fixedData, math.floor(v * 32))
    end
    return table.unpack(fixedData)
end

function module.fromFixedPoint(...:number):number...
    local data = {...}
    for i, v in ipairs(data) do
        data[i] = v / 32
    end
    return table.unpack(data)
end

function module.formatEntityPosition(position:EntityPosition):number...
    local data = {module.toFixedPoint(position.X, position.Y, position.Z)}
    table.insert(data, position.yaw)
    table.insert(data, position.pitch)
    return table.unpack(data)
end

return module