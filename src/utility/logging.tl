local ansicolors = require("ansicolors")
local globalSettings = {
    DEBUG = true,
    DEBUG_COOLDOWN = 0.1,
    DEBUG_LIMIT = 10,
    DEBUG_TIMEOUT = 5,
    COOLDOWN_TIME = 0.4,
    COOLDOWN_LIMIT = 5,
    COOLDOWN_TIMEOUT = 5
}

global record cooldown
    amount: number
    lastTime: number
end

local record Logger
    __index: Logger
    new: function(name:string): Logger
    name: string
    cooldowns: {string: cooldown}
    globalSettings: {string: any}
end
Logger.__index = Logger

local function checkCooldown(cool:cooldown, isDebug:boolean): boolean
    local cooled = false
    local time = os.clock()-cool.lastTime
    local settings = {
        COOLDOWN_TIME = isDebug and globalSettings.DEBUG_COOLDOWN or globalSettings.COOLDOWN_TIME,
        COOLDOWN_LIMIT = isDebug and globalSettings.DEBUG_LIMIT or globalSettings.COOLDOWN_LIMIT,
        COOLDOWN_TIMEOUT = isDebug and globalSettings.DEBUG_TIMEOUT or globalSettings.COOLDOWN_TIMEOUT
    }
    if time < settings.COOLDOWN_TIME or (cool.amount > settings.COOLDOWN_LIMIT and time < settings.COOLDOWN_TIMEOUT) then
        cool.amount = cool.amount + 1
        if cool.amount > settings.COOLDOWN_LIMIT then
            cooled = true
        end
    else 
        cool.amount = math.max(0, cool.amount - 1)
    end
    cool.lastTime = os.clock()
    return not cooled
end

function Logger:checkCooldown(message:string, isDebug:boolean|nil):boolean
    local cooldownTime:number do
        if isDebug then
            cooldownTime = globalSettings.DEBUG_COOLDOWN
        else
            cooldownTime = globalSettings.COOLDOWN_TIME
        end
    end
    if not self.cooldowns[message] then
        self.cooldowns[message] = {amount = 0, lastTime = os.clock()-cooldownTime}
    end
    local pass = checkCooldown(self.cooldowns[message], isDebug or false)
    if pass and os.clock() - self.cooldowns[message].lastTime > cooldownTime * 2 then
        self.cooldowns[message] = nil
    end
    return pass
end

local function makePattern(color:string, level:string): string
    local pattern = string.gsub("%{{color}}[{name}/{level}]: {message}%{reset}\n", "{color}", color):gsub("{level}", level)
    return ansicolors(pattern)
end
local enum levels 
    "debug"
    "info"
    "warn"
    "error"
    "fatal"
end
local patterns: {levels:string} = {
    debug = makePattern("bright black", "DEBUG"),
    info = makePattern("white", "INFO"),
    warn = makePattern("yellow", "WARN"),
    error = makePattern("red", "ERROR"),
    fatal = makePattern("bright dim red", "FATAL")
}

function Logger:sendMessage(level:levels, message: string, isDebug:boolean|nil)
    if self:checkCooldown(message, isDebug) then
        local pattern = patterns[level]
        local formatted = pattern:gsub("{name}", self.name):gsub("{message}", message)
        io.stderr:write(formatted)
    end
end

function Logger:Fatal(message: string)
    self:sendMessage("fatal",message.."\n"..debug.traceback())
end

function Logger:Error(message: string)
    self:sendMessage("error",message.."\n")
end

function Logger:Warn(message: string)
    self:sendMessage("warn",message)
end

function Logger:Info(message: string)
    self:sendMessage("info",message)
end

function Logger:Debug(message: string)
    if globalSettings.DEBUG then
        self:sendMessage("debug",message, true)
    end
end

function Logger:FormatErr(message:string): string -- For consistency when throwing with error()
    return string.format("%s: $s", self.name, message)
end

function Logger.new(name:string): Logger
    local self:Logger = setmetatable({}, Logger)
    self.name = name

    self.cooldowns = {}
    return self
end

Logger.globalSettings = globalSettings

return Logger