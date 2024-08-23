local currentRequire = require
--local tluvit = currentRequire('tluvit')
local fs = currentRequire('fs')
local pathModule = currentRequire('path')

local modulePath = "./src"

local function toPath(module)
    --[[local cachedSuffix = ""
    if module:sub(-5) == ".d.tl" then
        module = module:sub(1, -6)
        cachedSuffix = ".d.tl"
    elseif module:sub(-3) == ".tl" then
        module = module:sub(1, -4)
        cachedSuffix = ".tl"
    end]]
    module = module:gsub('%.', '/')
    return pathModule.resolve(pathModule.join(modulePath, module))--..cachedSuffix)
end

local types = {"lua", package.cpath:match("%p[\\|/]?%p(%a+)")}

local function customRequire(module)
    local path = toPath(module)
   -- local searchPath = pathModule.dirname(path)
    --local file = pathModule.basename(path)
    --if fs.existsSync(searchPath.."/"..file..".tl") then
        --return tluvit.loadtl(searchPath.."/"..file..".tl")
    for _, t in pairs(types) do
        if fs.existsSync(path.."."..t) then
            return currentRequire(path.."."..t)
        end
    end
    return currentRequire(module)
end

return customRequire