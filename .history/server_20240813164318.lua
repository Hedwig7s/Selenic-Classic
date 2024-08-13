---@class Server
local module = {}

---@class ServerInfo
module.info = {
    Version = "v0.1.3-alpha",
    Software = "Selenic Classic",
    Salt = (function ()
        local salt = ""
        for i=1, 16 do
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
        return salt
    end)()
}

return module