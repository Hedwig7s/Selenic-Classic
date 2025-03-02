local require = require("customrequire")
local Logger = require("utility.logging")
local tableUtility = require("utility.table")
local class = require("middleclass")
local toml = require("toml")
local fs = require("fs")
local pathModule = require("path")

SettingsTable = {}

Config = {}

local function parseKey(key, current, currentDefault)
	local path = {}
	for part in key:gmatch("([^%.]+)") do
		table.insert(path, part)
	end
	local subkey = path[#path]
	table.remove(path, #path)
	for i = 1, #path do
		local sub = current[path[i]]
		local subDefault = currentDefault[path[i]]
		if type(sub) == "table" and type(subDefault) == "table" then
			current = sub
			currentDefault = subDefault
		else
			return nil, path[i]
		end
	end
	return current, currentDefault, subkey
end

local config = class("Config")
function config:initialize(name, version, defaults, updaters)
	local self = self
	self.name = name
	self.version = version
	self.defaults = defaults
	self.updaters = updaters
	self.settings = {}
	self.loaded = false
	self.logger = Logger.new(name .. "-config")
end
function config:getConfigPath()
	return pathModule.join(pathModule.resolve("."), "config/" .. self.name .. ".toml")
end
function config:saveToFile()
	if not self.loaded then
		error(self.logger:FormatErr("Cannot save an unloaded config"))
		return
	end
	local copy = tableUtility.deepCopy(self.settings)
	copy.version = self.version
	local data = toml.encode(copy)
	xpcall(function()
		fs.writeFileSync(pathModule.join(pathModule.resolve("."), "config/" .. self.name .. ".toml"), data)
		self.logger:Debug("Saved successfully")
	end, function(err)
		error(self.logger:FormatErr("Failed to save: " .. (err and tostring(err)) or "Unknown error"))
	end)
end
function config:loadFromFile(reload)
	if self.loaded and not reload then
		self.logger:Warn("Attempted to load config when already loaded without reload")
		return
	end
	if not self.settings then
		error(self.logger:FormatErr("Cannot load into a nil settings table"))
		return
	end
	local filePath = self:getConfigPath()
	local exists = type(fs.statSync(pathModule.dirname(filePath))) == "table"
	if not exists then
		fs.mkdirSync(pathModule.dirname(filePath))
	end
	local function loadDefaults()
		if fs.existsSync(filePath) then
			fs.renameSync(filePath, filePath .. ".old")
		end
		self.settings = tableUtility.deepCopy(self.defaults)
		self.loaded = true
		self:saveToFile()
	end
	if not fs.existsSync(filePath) then
		self.logger:Warn("Config file does not exist. Creating a new one")
		loadDefaults()
		return
	end
	xpcall(function()
		local data = fs.readFileSync(filePath)
		local settings = toml.decode(data)
		local version = settings.version
		if not (type(version) == "number") then
			self.logger:Error("Config file does not have a version. Using defaults")
			loadDefaults()
			return
		end
		if self.updaters and version < self.version then
			self.logger:Debug("Running updaters on config")
			for i, updater in pairs(self.updaters) do
				if i >= self.version then
					break
				end
				updater(self)
			end
		end
		local function parseSettings(settings, defaults)
			for k, v in pairs(defaults) do
				if type(v) == "table" then
					if settings[k] == nil then
						settings[k] = tableUtility.deepCopy(v)
					else
						parseSettings(settings[k], v)
					end
				elseif settings[k] == nil then
					settings[k] = v
				elseif type(settings[k]) ~= type(v) then
					error(
						string.format(
							"Setting %s is not the correct type. Expected %s, got %s",
							k,
							type(settings[k]),
							type(v)
						)
					)
				end
			end
		end
		parseSettings(settings, self.defaults)
		self.settings = settings
		self.loaded = true
		self.logger:Debug("Loaded successfully")
		self:saveToFile()
	end, function(err)
		self.logger:Warn(
			"Failed to load config: " .. ((err and tostring(err)) or "Unknown error") .. ". Using defaults"
		)
		self.settings = tableUtility.deepCopy(self.defaults)
	end)
end
function config:get(key)
	local current, failedKey, subkey = parseKey(key, self.settings, self.defaults)
	if not current then
		self.logger:Error(string.format("Invalid key: %s. Failed at %s", key, failedKey))
	end
	local current, subkey = current, subkey
	return current[subkey]
end
function config:set(key, value)
	local current, currentDefault, subkey = parseKey(key, self.settings, self.defaults)
	if not current then
		self.logger:Error(string.format("Invalid key: %s. Failed at %s", key, currentDefault))
	end
	local current, currentDefault, subkey = current, currentDefault, subkey
	if currentDefault[subkey] and type(currentDefault[subkey]) ~= type(value) then
		self.logger:Error(
			string.format(
				"Setting %s is not the correct type. Expected %s, got %s",
				key,
				type(currentDefault[subkey]),
				type(value)
			)
		)
	end
	if currentDefault[subkey] then
		current[subkey] = value
	else
		self.logger:Error(string.format("Setting %s does not exist", key))
	end
end

return config
