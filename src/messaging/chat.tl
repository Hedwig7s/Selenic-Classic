local require = require("customrequire")
local base = require("messaging.base")
local cr = require("messaging.criterias")
local criterias = cr.criterias
local combineCriterias = cr.combineCriterias
local Logger = require("utility.logging")
local class = require("middleclass")

global type Chat = MessagingBase
local type Entities = require("entity.types")
local type Player = Entities.Player

local chatClass = class("Chat", base as class.Class) as Chat

function chatClass:RawSend(target:Player, message:string)
    local packet = target.connection.protocol:PacketFromName("Message")
    if packet is nil then
        self.logger:Error("Failed to send message to player, no message packet found")
        return
    end
    packet.sender(target.connection, 0, message)
end

function chatClass:ProcessMessage(target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData): string|nil
    if data and data.sourcePlayer then
        message = data.sourcePlayer.fancyName .. ": " .. message
    end
    message = base.ProcessMessage(self, target, message, criteria, data)

    return message
end
function chatClass:initialize()
    base.initialize(self)
    local self = self as Chat
    self.logger = Logger.new("Chat")
end

local cachedMessages: {string:{string}} = setmetatable({}, {
    __len = function(self:{string:{string}}): integer
        local count = 0
        for _ in pairs(self) do
            count = count + 1
        end
        return count
    end
})

local function splitMessage(message:string): {string}
    if cachedMessages[message] then
        return cachedMessages[message]
    elseif #(cachedMessages as {any}) --[[Hack fix]] > 5 then -- Limit the cache to 5 messages
        for k, v in pairs(cachedMessages) do
            if k and k ~= message then
                cachedMessages[k] = nil
                break
            end
        end
    end
    local newline = false

    local messages: {string} = {}
    local current: {string} = {}
    local word: {string} = {}
    local color:string
    local function addCurrent()
        if #current > 0 then
            local msg = table.concat(current):gsub("&$", "")
            table.insert(messages, msg)
        end
        current = newline and {} or {">", " ", color}
        newline = false
    end

    local function checkSize()
        if #current + #word > 64 then
            addCurrent()
        end
    end
    local function addWord()
        checkSize()
        for _, c in ipairs(word) do
            table.insert(current, c)
        end
        if #current < 64 then
            table.insert(current, " ")
        end
        word = {}
    end

    for i = 1, #message do
        local char = message:sub(i,i)
        if #word >= 61 then
            local cached = table.concat(word)
            for i = 1, #cached, 61 do
                word = {}
                for j = 1, 61 do
                    table.insert(word, cached:sub(i+j,i+j))
                end
                addWord()
            end
        end
        if char == "&" and i < #message and message:sub(i+1,i+1):match("[abcdefABCDEF%d]") then
            color = "&"..message:sub(i+1,i+1)
        end
        if char == " " then
            addWord()
        elseif char == "\n" then
            addWord()
            newline = true
            addCurrent()
            current = {}
        else
            table.insert(word, char)
        end
    end
    addWord()
    addCurrent()
    cachedMessages[message] = messages
    return messages
end

function chatClass:Message(target:Player, message:string, criteria:MessageCriteria, data:MessageCriteriaData)
    message = self:ProcessMessage(target, message, criteria, data)
    if message then
        for _, msg in ipairs(splitMessage(message)) do
            self:RawSend(target, msg)
        end
    end
end
return chatClass:new() as Chat