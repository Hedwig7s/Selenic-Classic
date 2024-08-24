local globalSettings = {
    DEBUG = true
}
global record Logger
    __index: Logger
    new: function(name:string): Logger
    name: string
    getPrefix: function(self:Logger, level:string): string
    Error: function(self:Logger, message:string, dontError:boolean|nil)
    Warn: function(self:Logger, message:string)
    Info: function(self:Logger, message:string)
    Debug: function(self:Logger, message:string)
end
Logger.__index = Logger

local function detailString(details:string, text:string): string
    return string.format("\27[%sm%s\27[0m", details, text)
end

function Logger:getPrefix(level:string): string
    return string.format("[%s/%s]: ", self.name, level)
end

function Logger:Error(message: string, dontError: boolean|nil)
    local func = dontError and print or error
    func(detailString("31",self:getPrefix("ERROR") .. message))
end

function Logger:Warn(message: string)
    print(detailString("33",self:getPrefix("WARN") .. message))
end

function Logger:Info(message: string)
    print(detailString("37",self:getPrefix("INFO") .. message))
end

function Logger:Debug(message: string)
    if globalSettings.DEBUG then
        print(detailString("1;30",self:getPrefix("DEBUG") .. message))
    end
end

function Logger.new(name:string): Logger
    local self:Logger = setmetatable({}, Logger)
    self.name = name
    return self
end

return Logger, globalSettings