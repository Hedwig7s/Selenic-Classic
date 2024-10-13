local enum flushMode
    "sync"
    "full"
    "finish"
end
local type checksum_compute = function(input:string|checksum_compute): integer
local type stream = function(input:string, mode?:flushMode): string
local record zlib
    version: function(): integer, integer, integer
    deflate: function(compression_level?:integer, window_size?:integer): stream
    inflate: function(windowBits?:integer): stream
    crc32: function(): checksum_compute
    adler32: function(): checksum_compute
end
return zlib