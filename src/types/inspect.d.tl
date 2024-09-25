local record inspect
    _VERSION: string
    _URL: string
    _DESCRIPTION: string
    _LICENSE: string
    KEY: table
    METATABLE: table
 
    type ProcessFunction = function(any, {any}): any
 
    record Options
       depth: integer
       newline: string
       indent: string
       process: ProcessFunction
    end
    metamethod __call: function(self:inspect, root:any, options:Options|nil): string
    inspect: function(root:any, options:Options|nil): string
 end
 
return inspect
