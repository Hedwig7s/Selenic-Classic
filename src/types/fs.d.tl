local record fileDescriptor
    userdata
end

local record stream
    userdata
end

local record fs
    -- File operations
    close: function(file:fileDescriptor, callback:function(err?:string))
    closeSync: function(file:fileDescriptor)
    open: function(path:string, flags:string, mode:integer, callback:function(err?:string, file?:fileDescriptor))
    openSync: function(path:string, flags:string, mode:integer): fileDescriptor
    read: function(file:fileDescriptor, size:number, offset:integer, callback:function(err?:string, bytesRead:integer, buffer:string))
    readSync: function(file:fileDescriptor, size:number, offset:integer): string
    write: function(file:fileDescriptor, offset?:integer, data:string, callback:function(err?:string))
    writeSync: function(file:fileDescriptor, offset?:integer, data:string)
    unlink: function(path:string, callback:function(err?:string))
    unlinkSync: function(path:string)

    -- Directory operations
    mkdir: function(path:string, mode?:integer, callback:function(err?:string))
    mkdirSync: function(path:string, mode?:integer)
    mkdtemp: function(template:string, callback:function(err?:string, folder?:string))
    mkdtempSync: function(template:string): string
    rmdir: function(path:string, callback:function(err?:string))
    rmdirSync: function(path:string)
    readdir: function(path:string, callback:function(err?:string, files:table))
    readdirSync: function(path:string): table
    scandir: function(path:string, callback:function(err?:string, iter:function():string))
    scandirSync: function(path:string): function():string

    -- Symbolic link operations
    symlink: function(target:string, path:string, type?:string, callback:function(err?:string))
    symlinkSync: function(target:string, path:string, type?:string)
    readlink: function(path:string, callback:function(err?:string, link?:string))
    readlinkSync: function(path:string): string

    -- File status operations
    stat: function(path:string, callback:function(err?:string, stat?:table))
    statSync: function(path:string): table
    lstat: function(path:string, callback:function(err?:string, stat?:table))
    lstatSync: function(path:string): table
    fstat: function(file:fileDescriptor, callback:function(err?:string, stat?:table))
    fstatSync: function(file:fileDescriptor): table

    -- File manipulation
    rename: function(oldPath:string, newPath:string, callback:function(err?:string))
    renameSync: function(oldPath:string, newPath:string)
    copyFile: function(src:string, dest:string, flags?:integer, callback:function(err?:string))
    copyFileSync: function(src:string, dest:string, flags?:integer)

    -- File descriptor operations
    fdatasync: function(file:fileDescriptor, callback:function(err?:string))
    fdatasyncSync: function(file:fileDescriptor)
    fsync: function(file:fileDescriptor, callback:function(err?:string))
    fsyncSync: function(file:fileDescriptor)

    -- Special operations
    truncate: function(path:string|fileDescriptor, len:integer, callback:function(err?:string))
    truncateSync: function(path:string|fileDescriptor, len:integer)
    utimes: function(path:string, atime:number, mtime:number, callback:function(err?:string))
    utimesSync: function(path:string, atime:number, mtime:number)
    futimes: function(file:fileDescriptor, atime:number, mtime:number, callback:function(err?:string))
    futimesSync: function(file:fileDescriptor, atime:number, mtime:number)

    -- File System Watcher
    watch: function(filename:string, options?:table, listener:function(event:string, filename?:string))
    watchFile: function(filename:string, options?:table, listener:function(curr:table, prev:table))
    unwatchFile: function(filename:string, listener?:function)

    -- Streams
    createReadStream: function(path:string, options?:table): stream
    createWriteStream: function(path:string, options?:table): stream

    -- Read, Write, Append File
    readFile: function(path:string, options?:string|table, callback:function(err?:string, data?:string))
    readFileSync: function(path:string, options?:string|table): string
    writeFile: function(path:string, data:string, options?:table, callback:function(err?:string))
    writeFileSync: function(path:string, data:string, options?:table)
    appendFile: function(path:string, data:string, options?:table, callback:function(err?:string))
    appendFileSync: function(path:string, data:string, options?:table)

    exists: function(path:string, callback:function(exists:boolean, err?:string))
    existsSync: function(path:string): boolean, string|nil
end

return fs
