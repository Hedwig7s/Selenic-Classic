local module = {}

function module.deepCopy(obj)
    if type(obj) ~= "table" then
        return obj
    end
    local copy = {}
    for k, v in pairs(obj) do
        copy[module.deepCopy(k)] = module.deepCopy(v)
    end
    return copy
end

function module.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function module.bytes(str)
    local t = {}
    for i = 1, #str do
        table.insert(t, str:sub(i, i):byte())
    end
    return unpack(t)
end

function module.merge(t1, t2)
    for k, v in pairs(t2) do
        if not t1[k] then
            t1[k] = v
        end
    end
    return t1
end

return module