local globalSettings = {
    DEBUG = true,
    DEBUG_COOLDOWN = 0.15,
    DEBUG_LIMIT = 10,
    DEBUG_TIMEOUT = 5,
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
    checkCooldown: function(self:Logger, message:string, debug:boolean): boolean
    Error: function(self:Logger, message:string, dontError:boolean|nil)
    Warn: function(self:Logger, message:string)
    Info: function(self:Logger, message:string)
    Debug: function(self:Logger, message:string)
    cooldowns: {string: cooldown}
end
Logger.__index = Logger

local function detailString(details:string, text:string): string
    return string.format("\27[%sm%s\27[0m", details, text)
end

local function checkCooldown(cool:cooldown, debug:boolean): boolean
    local cooled = false
    local time = os.clock()-cool.lastTime
    local settings = {
        COOLDOWN_TIME = debug and globalSettings.DEBUG_COOLDOWN or globalSettings.COOLDOWN_TIME,
        COOLDOWN_LIMIT = debug and globalSettings.DEBUG_LIMIT or globalSettings.COOLDOWN_LIMIT,
        COOLDOWN_TIMEOUT = debug and globalSettings.DEBUG_TIMEOUT or globalSettings.COOLDOWN_TIMEOUT
    }
    if time < settings.COOLDOWN_TIME or (cool.amount > settings.COOLDOWN_LIMIT and time < settings.COOLDOWN_TIMEOUT) then
        cool.amount = cool.amount + 1
        if cool.amount > settings.COOLDOWN_LIMIT then
            cooled = true
        end
    end
    cool.lastTime = os.clock()
    return not cooled
end

function Logger:checkCooldown(message:string, debug:boolean):boolean
    if not self.cooldowns[message] then
        self.cooldowns[message] = {amount = 0, lastTime = 0}
    end
    return checkCooldown(self.cooldowns[message], debug)
end

function Logger:sendMessage(debug:boolean, func:function(...:any), ...:string)
    local message = table.concat({...})
    if not self:checkCooldown(message, debug) then
        return
    end
    func(message)
end

function Logger:getPrefix(level:string): string
    return string.format("[%s/%s]: ", self.name, level)
end

function Logger:Error(message: string, dontError: boolean|nil)
    self:sendMessage(false, dontError and print or error, detailString("31",self:getPrefix("ERROR") .. message))
end

function Logger:Warn(message: string)
    self:sendMessage(false, print,detailString("33",self:getPrefix("WARN") .. message))
end

function Logger:Info(message: string)
    self:sendMessage(false, print,detailString("37",self:getPrefix("INFO") .. message))
end

function Logger:Debug(message: string)
    if globalSettings.DEBUG then
        self:sendMessage(true, print, detailString("1;30", self:getPrefix("DEBUG") .. message))
    end
end

function Logger.new(name:string): Logger
    local self:Logger = setmetatable({}, Logger)
    self.name = name
    self.cooldowns = {}
    return self
end

return Logger, globalSettings