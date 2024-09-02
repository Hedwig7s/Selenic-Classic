local require = require("customrequire")
local core = require("core")
local Object = core.Object
local Logger = require("utility.logging")
local tableUtility = require("utility.table")  
local toml = require("toml")
local fs = require("fs")
local pathModule = require("path")


global type SettingsTable = {string: any}

global record Config 
    initialize: function(self:Config, name:string, defaults: {string: any})
    new: function(self:Config, name:string, defaults: {string: any}): Config
    extend: function(self:Config): Config
    name: string
    defaults: SettingsTable
    settings: SettingsTable
    loaded: boolean
    logger: Logger
    getConfigPath: function(self:Config): string
    loadFromFile: function(self:Config, reload:boolean|nil)
    saveToFile: function(self:Config)
    get: function(self:Config, key:string): any
    set: function(self:Config, key:string, value:any)
end

local function parseKey(key:string, current:SettingsTable, currentDefault:SettingsTable): SettingsTable| nil, SettingsTable|string, any 
    local path = {}
    for part in key:gmatch("([^%.]+)") do
        table.insert(path, part)
    end
    local subkey = path[#path]
    table.remove(path, #path)
    for i = 1, #path do
        local sub = current[path[i]]
        local subDefault = currentDefault[path[i]]
        if sub is SettingsTable and subDefault is SettingsTable then
            current = sub
            currentDefault = subDefault
        else
            return nil, path[i]
        end
    end
    return current, currentDefault, subkey
end

local config = Object:extend() as Config
function config:initialize(name:string, defaults: {string: any})
    local self = self as Config
    self.name = name
    self.defaults = defaults
    self.settings = {}
    self.loaded = false
    self.logger = Logger.new(name.."-config")
end
function config:getConfigPath(): string
    return pathModule.join(pathModule.resolve("."), "config/"..self.name..".toml")
end
function config:saveToFile()
    if not self.loaded then
        self.logger:Error("Cannot save an unloaded config")
        return
    end
    local data = toml.encode(self.settings)
    xpcall(function()
        fs.writeFileSync(pathModule.join(pathModule.resolve("."), "config/"..self.name..".toml"), data)
        self.logger:Debug("Saved successfully")
    end, function(err)
        self.logger:Error("Failed to save: "..(err and tostring(err)) or "Unknown error")
    end)
end
function config:loadFromFile(reload:boolean|nil)
    if self.loaded and not reload then
        self.logger:Warn("Attempted to load config when already loaded without reload")
        return
    end
    local filePath = self:getConfigPath()
    local exists = type(fs.statSync(pathModule.dirname(filePath))) == "table"
    if not exists then
        fs.mkdirSync(pathModule.dirname(filePath))
    end
    if not fs.existsSync(filePath) then
        self.logger:Warn("Config file does not exist. Creating a new one")
        self.settings = tableUtility.deepCopy(self.defaults) as SettingsTable
        self.loaded = true
        self:saveToFile()
        return
    end
    xpcall(function()
        local data = fs.readFileSync(filePath)
        local settings = toml.decode(data)
        
        local function parseSettings(settings:SettingsTable, defaults:SettingsTable)
            for k, v in pairs(defaults) do
                if v is table then
                    if settings[k] == nil then
                        settings[k] = tableUtility.deepCopy(v)
                    else
                        parseSettings(settings[k] as SettingsTable, v as SettingsTable)
                    end
                elseif settings[k] == nil then
                    settings[k] = v
                elseif type(settings[k]) ~= type(v) then
                    self.logger:Error(string.format("Setting %s is not the correct type. Expected %s, got %s", k, type(settings[k]), type(v)))
                end
            end
        end
        parseSettings(settings, self.defaults)
        self.settings = settings
        self.loaded = true
        self.logger:Debug("Loaded successfully")
        self:saveToFile()
    end, function(err)
        self.logger:Error("Failed to load config: "..(err and tostring(err)) or "Unknown error")
    end)
    
end
function config:get(key:string): any
    local current, failedKey, subkey = parseKey(key, self.settings, self.defaults)
    if not current then
        self.logger:Error(string.format("Invalid key: %s. Failed at %s", key, failedKey))
    end
    local current, subkey = current as SettingsTable, subkey as string
    return current[subkey]
end
function config:set(key:string, value:any)
    local current, currentDefault, subkey = parseKey(key, self.settings, self.defaults)
    if not current then
        self.logger:Error(string.format("Invalid key: %s. Failed at %s", key, currentDefault))
    end
    local current, currentDefault, subkey = current as SettingsTable, currentDefault as SettingsTable, subkey as string
    if currentDefault[subkey] and type(currentDefault[subkey]) ~= type(value) then
        self.logger:Error(string.format("Setting %s is not the correct type. Expected %s, got %s", key, type(currentDefault[subkey]), type(value)))
    end
    if currentDefault[subkey] then
        current[subkey] = value
    else
        self.logger:Error(string.format("Setting %s does not exist", key))
    end
end


return config