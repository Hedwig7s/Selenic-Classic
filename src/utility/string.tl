local module = {}

module.split = function(str: string, sep: string): {string}
    local t = {}
    for s in str:gmatch("([^"..sep.."]+)") do
        table.insert(t, s)
    end
    return t
end

return module