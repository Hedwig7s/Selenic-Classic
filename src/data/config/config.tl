local require = require("customrequire")
local class = require("class")
local logging = require("logging")
local tableUtility = require("deps/utility/table")  
local toml = require("toml")
local fs = require("fs")
local pathModule = require("path")

global record Config 
    __class__: BaseClass
    name: string
    defaults: {string: any}
    settings: {string: any}
    loaded: boolean
    logger: Logger
    loadFromFile: function(self:Config)
end

local configClass = class("Config", {
    constructor = function(self:Instance, _:BaseClass|nil, name:string, defaults: {string: any})
        local self = self as Config
        self.name = name
        self.defaults = defaults
        self.settings = {}
        self.loaded = false
        self.logger = logging.new(name.." Config")
    end,
    values = {
        saveToFile = function(self:Config)
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
        end,
        loadFromFile = function(self:Config, force:boolean|nil)
            if self.loaded and not force then
                self.logger:Warn("Attempted to load config when already loaded without force")
                return
            end
            local data = fs.readFileSync(pathModule.join(pathModule.resolve("."), "config/"..self.name..".toml"))
            local settings = toml.decode(data)
            local function parseSettings(settings:{string:any}, defaults:{string:any})
                for k, v in pairs(defaults) do
                    if v is table then
                        if not settings[k] then
                            settings[k] = tableUtility.deepCopy(v)
                        else
                            parseSettings(settings[k] as {string:any}, v as {string:any})
                        end
                    elseif not settings[k] then
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
        end,
        get = function(self:Config, key:string): any
            return self.settings[key]
        end,
        set = function(self:Config, key:string, value:any)
            local path = {}
            for part in key:gmatch("([^%.]+)") do
                table.insert(path, part)
            end
            local current = self.settings
            local currentDefault = self.defaults
            local subkey = path[#path]
            table.remove(path, #path)
            for i = 1, #path do
                local sub = current[path[i]]
                local subDefault = currentDefault[path[i]]
                if sub is {string:any} and subDefault is {string:any} then
                    current = sub
                    currentDefault = subDefault
                else
                    self.logger:Error(string.format("Invalid key: %s. Failed at %s", key, path[i]))
                end
            end
            if currentDefault[subkey] and type(currentDefault[subkey]) ~= type(value) then
                self.logger:Error(string.format("Setting %s is not the correct type. Expected %s, got %s", key, type(currentDefault[subkey]), type(value)))
            end
            if currentDefault[subkey] then
                current[subkey] = value
            else
                self.logger:Error(string.format("Setting %s does not exist", key))
            end
        end,
    }
})

return configClass