local record fileDescriptor
    userdata
end

local record stream
    userdata
end

local record fs
    -- File operations
    close: function(file:fileDescriptor, callback:function(err:string|nil))
    closeSync: function(file:fileDescriptor)
    open: function(path:string, flags:string, mode:integer, callback:function(err:string|nil, file:fileDescriptor|nil))
    openSync: function(path:string, flags:string, mode:integer): fileDescriptor
    read: function(file:fileDescriptor, size:number, offset:integer, callback:function(err:string|nil, bytesRead:integer, buffer:string))
    readSync: function(file:fileDescriptor, size:number, offset:integer): string
    write: function(file:fileDescriptor, offset:integer|nil, data:string, callback:function(err:string|nil))
    writeSync: function(file:fileDescriptor, offset:integer|nil, data:string)
    unlink: function(path:string, callback:function(err:string|nil))
    unlinkSync: function(path:string)

    -- Directory operations
    mkdir: function(path:string, mode:integer|nil, callback:function(err:string|nil))
    mkdirSync: function(path:string, mode:integer|nil)
    mkdtemp: function(template:string, callback:function(err:string|nil, folder:string|nil))
    mkdtempSync: function(template:string): string
    rmdir: function(path:string, callback:function(err:string|nil))
    rmdirSync: function(path:string)
    readdir: function(path:string, callback:function(err:string|nil, files:table))
    readdirSync: function(path:string): table
    scandir: function(path:string, callback:function(err:string|nil, iter:function():string))
    scandirSync: function(path:string): function():string

    -- Symbolic link operations
    symlink: function(target:string, path:string, type:string|nil, callback:function(err:string|nil))
    symlinkSync: function(target:string, path:string, type:string|nil)
    readlink: function(path:string, callback:function(err:string|nil, link:string|nil))
    readlinkSync: function(path:string): string

    -- File status operations
    stat: function(path:string, callback:function(err:string|nil, stat:table|nil))
    statSync: function(path:string): table
    lstat: function(path:string, callback:function(err:string|nil, stat:table|nil))
    lstatSync: function(path:string): table
    fstat: function(file:fileDescriptor, callback:function(err:string|nil, stat:table|nil))
    fstatSync: function(file:fileDescriptor): table

    -- File manipulation
    rename: function(oldPath:string, newPath:string, callback:function(err:string|nil))
    renameSync: function(oldPath:string, newPath:string)
    copyFile: function(src:string, dest:string, flags:integer|nil, callback:function(err:string|nil))
    copyFileSync: function(src:string, dest:string, flags:integer|nil)

    -- File descriptor operations
    fdatasync: function(file:fileDescriptor, callback:function(err:string|nil))
    fdatasyncSync: function(file:fileDescriptor)
    fsync: function(file:fileDescriptor, callback:function(err:string|nil))
    fsyncSync: function(file:fileDescriptor)

    -- Special operations
    truncate: function(path:string|fileDescriptor, len:integer, callback:function(err:string|nil))
    truncateSync: function(path:string|fileDescriptor, len:integer)
    utimes: function(path:string, atime:number, mtime:number, callback:function(err:string|nil))
    utimesSync: function(path:string, atime:number, mtime:number)
    futimes: function(file:fileDescriptor, atime:number, mtime:number, callback:function(err:string|nil))
    futimesSync: function(file:fileDescriptor, atime:number, mtime:number)

    -- File System Watcher
    watch: function(filename:string, options:table|nil, listener:function(event:string, filename:string|nil))
    watchFile: function(filename:string, options:table|nil, listener:function(curr:table, prev:table))
    unwatchFile: function(filename:string, listener:function|nil)

    -- Streams
    createReadStream: function(path:string, options:table|nil): stream
    createWriteStream: function(path:string, options:table|nil): stream

    -- Read, Write, Append File
    readFile: function(path:string, options:string|table|nil, callback:function(err:string|nil, data:string|nil))
    readFileSync: function(path:string, options:string|table|nil): string
    writeFile: function(path:string, data:string, options:table|nil, callback:function(err:string|nil))
    writeFileSync: function(path:string, data:string, options:table|nil)
    appendFile: function(path:string, data:string, options:table|nil, callback:function(err:string|nil))
    appendFileSync: function(path:string, data:string, options:table|nil)

    exists: function(path:string, callback:function(exists:boolean, err:string|nil))
    existsSync: function(path:string): boolean, string|nil
end

return fs
