local record Timer
    userdata
end
local record Item
    userdata
end
local record timer 
    sleep: function(delay:number, thread:thread|nil)
    setTimeout: function(delay:number, callback:function, ...:any): Timer
    setInterval: function(interval:number, callback:function, ...:any): Timer
    clearInterval: function(timer:Timer)
    clearTimeout: function(timer:Timer)
    clearTimer: function(timer:Timer)
    setImmediate: function(callback:function, ...:any): Timer
    unenroll: function(item:Item)
    enroll: function(time:number, msecs:number):Item -- No clue what this does
    active: function(item:Item): boolean
end

return timer