---@meta

---@class Command
---@field public NAME string
---@field public DESCRIPTION string
---@field public USAGE string
---@field public ALIASES table<string>?
---@field public execute fun(player: Player, args: table<string>): boolean, string?