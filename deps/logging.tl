local globalSettings = {
    DEBUG = true,
    COOLDOWN_TIME = 0.3,
    COOLDOWN_LIMIT = 5,
    COOLDOWN_TIMEOUT = 10
}

global record cooldown
    amount: number
    lastTime: number
end
global record Logger
    __index: Logger
    new: function(name:string): Logger
    name: string
    getPrefix: function(self:Logger, level:string): string
    checkCooldown: function(self:Logger, message:string): boolean
    Error: function(self:Logger, message:string, dontError:boolean|nil)
    Warn: function(self:Logger, message:string)
    Info: function(self:Logger, message:string)
    Debug: function(self:Logger, message:string)
    cooldowns: {string: cooldown}
    globalCooldown: cooldown
end
Logger.__index = Logger

local function detailString(details:string, text:string): string
    return string.format("\27[%sm%s\27[0m", details, text)
end

local function checkCooldown(cool:cooldown): boolean
    local cooled = false
    local time = os.clock()-cool.lastTime
    if time < globalSettings.COOLDOWN_TIME or (cool.amount > globalSettings.COOLDOWN_LIMIT and time < globalSettings.COOLDOWN_TIMEOUT) then
        cool.amount = cool.amount + 1
        if cool.amount > globalSettings.COOLDOWN_LIMIT then
            cooled = true
        end
    end
    cool.lastTime = os.clock()
    return not cooled
end

function Logger:checkCooldown(message:string):boolean
    if not self.cooldowns[message] then
        self.cooldowns[message] = {amount = 0, lastTime = 0}
    end
    
    return checkCooldown(self.globalCooldown) and checkCooldown(self.cooldowns[message])
end

function Logger:sendMessage(func:function(...:any), ...:string)
    local message = table.concat({...})
    if not self:checkCooldown(message) then
        return
    end
    func(message)
end

function Logger:getPrefix(level:string): string
    return string.format("[%s/%s]: ", self.name, level)
end

function Logger:Error(message: string, dontError: boolean|nil)
    self:sendMessage(dontError and print or error, detailString("31",self:getPrefix("ERROR") .. message))
end

function Logger:Warn(message: string)
    self:sendMessage(print,detailString("33",self:getPrefix("WARN") .. message))
end

function Logger:Info(message: string)
    self:sendMessage(print,detailString("37",self:getPrefix("INFO") .. message))
end

function Logger:Debug(message: string)
    if globalSettings.DEBUG then
        self:sendMessage(print,detailString("1;30",self:getPrefix("DEBUG") .. message))
    end
end

function Logger.new(name:string): Logger
    local self:Logger = setmetatable({}, Logger)
    self.name = name
    self.cooldowns = {}
    self.globalCooldown = {amount = 0, lastTime = 0}
    return self
end

return Logger, globalSettings