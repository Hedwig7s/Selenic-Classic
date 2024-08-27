local record Worker
    queue: function(self:Worker, ...:any)
    dumped: string
    bundlePaths:string
    record handler
        userdata
    end
end

local record uv_thread
    userdata
end

local type thread_func = function(...:any):any...

local record threadModule
    work: function(thread_func:thread_func, notify_entry:boolean): Worker
    queue: function(worker:Worker, ...:any)
    self: function():any
    join: function(thread:uv_thread): any
    start: function(thread_func:thread_func, ...:any): uv_thread
    equals: function(thread1:uv_thread, thread2:uv_thread): boolean
end
return threadModule