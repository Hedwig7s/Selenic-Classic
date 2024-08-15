---@class CommandHelp: Command

local lazyLoaded = {}

local function lazyLoad(module)
    if not lazyLoaded[module] then
        lazyLoaded[module] = require(module)
    end
    return lazyLoaded[module]
end

local pageList

---Executes the command
---@param player Player
---@param args table<string>
local function execute(player, args)
    local commands = lazyLoad("../commands")
    local command = args[1]
    local page = tonumber(command) or 1
    if command and #command ~= 0 and not tonumber(command) then
        command = command:lower()
        local commandModule = commands.commands[command] or commands.aliases[command]
        if not commandModule then
            return false, "Unknown command: " .. command
        end
        local message = [[
&bCommand: &e%s
&bDescription: &f%s
&bUsage: &e%s]]
        player:SendMessage(message:format(commandModule.NAME, commandModule.DESCRIPTION, commandModule.USAGE))
        if commandModule.ALIASES then
            player:SendMessage("&9Aliases: &e" .. table.concat(commandModule.ALIASES, ", "))
        end
    else
        if not pageList then
            local helpList = {}
            for _, value in pairs(commands.commands) do
                table.insert(helpList, "&a" .. value.NAME .. ": &f" .. value.DESCRIPTION)
            end
            table.sort(helpList)
            table.insert(helpList, "&bAliases:")
            local aliases = {}
            for _, value in pairs(commands.commands) do
                if value.ALIASES then
                    table.insert(aliases, "&a" .. value.NAME .. ": &e" .. table.concat(value.ALIASES, ", "))
                end
            end
            table.sort(aliases)
            for _, value in ipairs(aliases) do
                table.insert(helpList, value)
            end
            pageList = {}
            for i,v in pairs(helpList) do
                local page = math.floor(i/20)+1
                if not pageList[page] then
                    pageList[page] = {}
                end
                table.insert(pageList[page], v)
            end
        end
        player:SendMessage("&9Commands: ")
        if pageList[page] then
            for _, value in pairs(pageList[page]) do
                player:SendMessage(value)
            end
        end
        player:SendMessage("&ePage: &f" .. page .. "/" .. #pageList)
    end
    return true
end

return {
    NAME = "help",
    DESCRIPTION = "Gives information about a command, or lists all commands",
    USAGE = "/help [command]",
    execute = execute,
    ALIASES = {"?", "h", "commands", "cmd", "cmds", "commandlist", "cmdlist"}
}