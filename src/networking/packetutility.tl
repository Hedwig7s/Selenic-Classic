local module = {}
local require = require("customrequire")
local type _ = require("networking.servertypes")

function module.sendPacket(connection:Connection, format:string, ...:any): string
    return connection:write(string.pack(format, ...))
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

return module