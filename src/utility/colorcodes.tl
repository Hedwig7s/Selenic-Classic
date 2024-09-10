local module = {}

local replacements: {string:string} = {
    ["black"] = "&0",
    ["dark blue"] = "&1",
    ["dark green"] = "&2",
    ["dark teal"] = "&3",
    ["dark red"] = "&4",
    ["purple"] = "&5",
    ["gold"] = "&6",
    ["gray"] = "&7",
    ["dark gray"] = "&8",
    ["blue"] = "&9",
    ["green"] = "&a",
    ["teal"] = "&b",
    ["red"] = "&c",
    ["pink"] = "&d",
    ["yellow"] = "&e",
    ["white"] = "&f",
    ["reset"] = "&f",

}

local function parse(str:string):string
    str = str:gsub("{(.*)}", function(match:string):string
        return replacements[match] or match
    end)
    return str
end
return parse