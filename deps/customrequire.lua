local currentRequire = require
local tluvit = currentRequire('tluvit')
local fs = currentRequire('fs')
local pathModule = currentRequire('path')

local modulePath = "./"

local function toPath(module)
    local cachedSuffix = ""
    if module:sub(-5) == ".d.tl" then
        module = module:sub(1, -6)
        cachedSuffix = ".d.tl"
    elseif module:sub(-3) == ".tl" then
        module = module:sub(1, -4)
        cachedSuffix = ".tl"
    end
    return pathModule.resolve(modulePath..module:gsub('%.', '/')..cachedSuffix)
end

local function customRequire(module)
    local path = toPath(module)
    local searchPath = pathModule.dirname(path)
    local file = pathModule.basename(path)
    if fs.existsSync(searchPath.."/"..file..".tl") then
        return tluvit.loadtl(searchPath.."/"..file..".tl")
    elseif fs.existsSync(searchPath.."/"..file..".lua") then
        return currentRequire(searchPath.."/"..file..".lua")
    end

    return currentRequire(module)
end

return customRequire