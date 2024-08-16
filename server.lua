---@class Server
local module = {}

local fs = require("fs")
local util = require("./util")
local timer = require("timer")

local salt = ""
for i=1, 32 do
    local t = math.random(1,3)
    local num
    if t == 1 then
        num = math.random(48,57)
    elseif t == 2 then
        num = math.random(65,90)
    else
        num = math.random(97,122)
    end
    salt = salt .. string.char(num)
end

local function writeSalt()
    fs.writeFileSync("cachedSalt.txt", salt..":"..os.time())
end

if fs.existsSync("cachedSalt.txt") then
    local success, err = pcall(function()
        local saltData = util.split(fs.readFileSync("cachedSalt.txt"),":")
        local oldSalt, time = saltData[1], saltData[2]
        if not time or not oldSalt then
            error("Salt data invalid")
        end
        time = tonumber(time)
        if not time then
            error("Salt time invalid")
        end
        if os.time() - time < 600 then
            salt = oldSalt
        end
    end)
    if not success and err then
        print("Error reading salt data: "..err) -- Not critical
    end
end
writeSalt()
timer.setInterval(60000, writeSalt)
---@class ServerInfo
module.info = {
    Version = "v0.5.5-alpha",
    Software = "Selenic Classic",
    Source = "https://github.com/Hedwig7s/Selenic-Classic",
    Salt = salt
}

return module