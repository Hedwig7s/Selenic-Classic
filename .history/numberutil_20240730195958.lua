local module = {}

local bit32 = require("bit32")

function module:tou8(x)
    return string.char(x)
end

function module:fromu8(x)
    return string.byte(x)
end

function module:tou16(x)
    return string.char(x % 256, math.floor(x / 256))
end

function module:fromu16(x)
    return string.byte(x, 1) + string.byte(x, 2) * 256
end

function module:tou32(x)
    return string.char(x % 256, math.floor(x / 256) % 256, math.floor(x / 65536) % 256, math.floor(x / 16777216) % 256)
end

function module:fromu32(x)
    return string.byte(x, 1) + string.byte(x, 2) * 256 + string.byte(x, 3) * 65536 + string.byte(x, 4) * 16777216
end

function module:tou64(x)
    return string.char(x % 256, math.floor(x / 256) % 256, math.floor(x / 65536) % 256, math.floor(x / 16777216) % 256, math.floor(x / 4294967296) % 256, math.floor(x / 1099511627776) % 256, math.floor(x / 281474976710656) % 256, math.floor(x / 72057594037927936) % 256)
end

function module:fromu64(x)
    return string.byte(x, 1) + string.byte(x, 2) * 256 + string.byte(x, 3) * 65536 + string.byte(x, 4) * 16777216 + string.byte(x, 5) * 4294967296 + string.byte(x, 6) * 1099511627776 + string.byte(x, 7) * 281474976710656 + string.byte(x, 8) * 72057594037927936
end

function module:toshort(x)
    local buffer = string.char(bit32.band(x, 0xFF), bit32.rshift(x, 8))
    return buffer
end

function module:fromshort(x)
    local b1, b2 = string.byte(x, 1, 2)
    local short = b1 + bit32.lshift(b2, 8)
    return (short > 32767) and (short - 65536) or short
end

function module:tobyte(x)
    if x < 0 then
        x = x + 128
    end
    return string.char(x)
end

function module:frombyte(x)
    local x = string.byte(x)
    if x >= 128 then
        x = x - 128
    end
    return x
end

return module