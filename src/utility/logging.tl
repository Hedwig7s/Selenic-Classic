local logging = require("logging")
local ansicolors = require("ansicolors")
logging.console = require("../../deps/logging/console")
local globalSettings = {
    DEBUG = true,
    DEBUG_COOLDOWN = 0.05,
    DEBUG_LIMIT = 10,
    DEBUG_TIMEOUT = 5,
    COOLDOWN_TIME = 0.15,
    COOLDOWN_LIMIT = 5,
    COOLDOWN_TIMEOUT = 5
}

global record cooldown
    amount: number
    lastTime: number
end

local enum logFunctions
    "fatal"
    "error"
    "warn"
    "info"
    "debug"
end

local record Logger
    __index: Logger
    logger: logging.Log
    new: function(name:string): Logger
    extend: function(self:Logger):  Logger
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
    end
    cool.lastTime = os.clock()
    return not cooled
end

function Logger:checkCooldown(message:string, isDebug:boolean|nil):boolean
    if not self.cooldowns[message] then
        self.cooldowns[message] = {amount = 0, lastTime = 0}
    end
    return checkCooldown(self.cooldowns[message], isDebug or false)
end

function Logger:sendMessage(funcName: logFunctions, message: string, isDebug:boolean|nil)
    if self:checkCooldown(message, isDebug) then
        self.logger[funcName](self.logger, message)
    end
end

function Logger:Fatal(message: string, dontExit:boolean|nil)
    self:sendMessage("fatal", message.."\n"..debug.traceback())
    if not dontExit then
        os.exit(-1)
    end
end

function Logger:Error(message: string, dontError:boolean|nil)
    self:sendMessage("error", message.."\n")
    if not dontError then
        error(message)
    end
end

function Logger:Warn(message: string)
    self:sendMessage("warn", message)
end

function Logger:Info(message: string)
    self:sendMessage("info", message)
end

function Logger:Debug(message: string)
    if globalSettings.DEBUG then
        self:sendMessage("debug", message, true)
    end
end

local function makePattern(color:string, name:string): string
    local pattern = string.gsub("%{{color}}[{name}/%level]: %message%{reset}\n", "{color}", color):gsub("{name}", name)
    return ansicolors(pattern)
end

function Logger.new(name:string): Logger
    local self:Logger = setmetatable({}, Logger)
    self.name = name
    self.logger = logging.console({
        logLevel = logging.DEBUG,
        destination = "stderr",
        logPatterns = {
            [logging.DEBUG] = makePattern("black bright", name),
            [logging.INFO] = makePattern("white", name),
            [logging.WARN] = makePattern("yellow", name),
            [logging.ERROR] = makePattern("red", name),
            [logging.FATAL] = makePattern("red bright", name)
        },
    })
    self.cooldowns = {}
    return self
end

Logger.globalSettings = globalSettings

return Logger