local type uv = require("uv")
local record prettyPrint 
    enum colors
        "property"
        "sep"
        "braces"
    
        "nil"
        "boolean"
        "number"
        "string"
        "quotes"
        "escape"
        "function"
        "thread"
    
        "table"
        "userdata"
        "cdata"
    
        "err"
        "success"
        "failure"
        "highlight"
    end
    prettyPrint: function(...:any)
    print: function(...:any)
    dump: function(value:any, recurse:boolean, nocolor:boolean):string
    colorize: function(colorName:colors, string:string, resetName:string):string
    color: function(colorName:colors):string
    stdin: uv.Tty
    stdout: uv.Tty
    stderr: uv.Tty
    strip: function(str:string):string
end
return prettyPrint