local module = {}

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
    return string.char(x % 256, math.floor(x / 256))
end

function module:fromshort(x)
    return string.byte(x, 1) + string.byte(x, 2) * 256
end

return module