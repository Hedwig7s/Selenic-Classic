local enum flushMode
    "sync"
    "full"
    "finish"
end
local type checksum_compute = function(input:string|checksum_compute): integer
local type stream = function(input:string, mode:flushMode|nil): string
local record zlib
    version: function(): integer, integer, integer
    deflate: function(compression_level:integer|nil, window_size:integer|nil): stream
    inflate: function(windowBits:integer|nil): stream
    crc32: function(): checksum_compute
    adler32: function(): checksum_compute
end
return zlib