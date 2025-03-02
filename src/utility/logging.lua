local ansicolors = require("ansicolors")

local stringify
local write
do
	local function createWrite(stringifier, printer)
		stringify = function(...)
			local n = select("#", ...)
			local arguments = { ... }
			for i = 1, n do
				local arg = arguments[i]
				if not (type(arg) == "string") then
					arguments[i] = stringifier(arg)
				end
			end
			return table.concat(arguments, "\t")
		end
		write = function(...)
			printer(table.concat({ ... }, " "))
		end
	end
	local success, prettyPrint = pcall(require, "pretty-print")
	if success then
		createWrite(prettyPrint.dump, function(str)
			prettyPrint.stderr:write(str)
		end)
	else
		local success, pprint = pcall(require, "pprint")
		if success then
			createWrite(pprint.pformat, function(str)
				io.stderr:write(str)
			end)
		else
			local success, inspect = pcall(require, "inspect")
			if success then
				createWrite(inspect.inspect, function(str)
					io.stderr:write(str)
				end)
			else
				createWrite(tostring, function(str)
					io.stderr:write(str)
				end)
			end
		end
	end
end

local globalSettings = {
	DEBUG = true,
	DEBUG_COOLDOWN = 0.1,
	DEBUG_LIMIT = 10,
	DEBUG_TIMEOUT = 5,
	COOLDOWN_TIME = 0.4,
	COOLDOWN_LIMIT = 5,
	COOLDOWN_TIMEOUT = 5,
}

cooldown = {}

local Logger = {}

Logger.__index = Logger

local function checkCooldown(cool, isDebug)
	local cooled = false
	local time = os.clock() - cool.lastTime
	local settings = {
		COOLDOWN_TIME = isDebug and globalSettings.DEBUG_COOLDOWN or globalSettings.COOLDOWN_TIME,
		COOLDOWN_LIMIT = isDebug and globalSettings.DEBUG_LIMIT or globalSettings.COOLDOWN_LIMIT,
		COOLDOWN_TIMEOUT = isDebug and globalSettings.DEBUG_TIMEOUT or globalSettings.COOLDOWN_TIMEOUT,
	}
	if
		time < settings.COOLDOWN_TIME or (cool.amount > settings.COOLDOWN_LIMIT and time < settings.COOLDOWN_TIMEOUT)
	then
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

function Logger:checkCooldown(message, isDebug)
	local cooldownTime
	do
		if isDebug then
			cooldownTime = globalSettings.DEBUG_COOLDOWN
		else
			cooldownTime = globalSettings.COOLDOWN_TIME
		end
	end
	if not self.cooldowns[message] then
		self.cooldowns[message] = { amount = 0, lastTime = os.clock() - cooldownTime }
	end
	local pass = checkCooldown(self.cooldowns[message], isDebug or false)
	if pass and os.clock() - self.cooldowns[message].lastTime > cooldownTime * 2 then
		self.cooldowns[message] = nil
	end
	return pass
end

local function makePattern(color, level)
	local pattern =
		string.gsub("%{{color}}[{name}/{level}]: {message}%{reset}\n", "{color}", color):gsub("{level}", level)
	return ansicolors(pattern)
end

local patterns = {
	debug = makePattern("bright black", "DEBUG"),
	info = makePattern("white", "INFO"),
	warn = makePattern("yellow", "WARN"),
	error = makePattern("red", "ERROR"),
	fatal = makePattern("bright dim red", "FATAL"),
}

function Logger:sendMessage(level, message, isDebug)
	if self:checkCooldown(message, isDebug) then
		local pattern = patterns[level]
		local formatted = pattern:gsub("{name}", self.name):gsub("{message}", message)
		write(formatted)
	end
end

function Logger:Fatal(...)
	local message = stringify(...)
	self:sendMessage("fatal", message .. "\n" .. debug.traceback())
end

function Logger:Error(...)
	local message = stringify(...)
	self:sendMessage("error", message .. "\n" .. debug.traceback())
end

function Logger:Warn(...)
	local message = stringify(...)
	self:sendMessage("warn", message)
end

function Logger:Info(...)
	local message = stringify(...)
	self:sendMessage("info", message)
end

function Logger:Debug(...)
	if globalSettings.DEBUG then
		local message = stringify(...)
		self:sendMessage("debug", message, true)
	end
end

function Logger:FormatErr(...)
	local message = stringify(...)
	return string.format("%s: $s", self.name, message)
end

function Logger.new(name)
	local self = setmetatable({}, Logger)
	self.name = name

	self.cooldowns = {}
	return self
end

Logger.globalSettings = globalSettings

return Logger
