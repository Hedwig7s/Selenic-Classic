local record buffer
    record Buffer
        initialize: function(self:buffer.Buffer, size:integer)
        new: function(self:buffer.Buffer, size:integer): buffer.Buffer
        inspect: function(self:buffer.Buffer): string
        readUInt8: function(self:buffer.Buffer, offset:integer): integer
        readInt8: function(self:buffer.Buffer, offset:integer): integer
        readUInt16LE: function(self:buffer.Buffer, offset:integer): integer
        readUInt16BE: function(self:buffer.Buffer, offset:integer): integer
        readInt16LE: function(self:buffer.Buffer, offset:integer): integer
        readInt16BE: function(self:buffer.Buffer, offset:integer): integer
        readUInt32LE: function(self:buffer.Buffer, offset:integer): integer
        readUInt32BE: function(self:buffer.Buffer, offset:integer): integer
        readInt32LE: function(self:buffer.Buffer, offset:integer): integer
        readInt32BE: function(self:buffer.Buffer, offset:integer): integer
        writeUInt8: function(self:buffer.Buffer, offset:integer, value:integer)
        writeInt8: function(self:buffer.Buffer, offset:integer, value:integer)
        writeUInt16LE: function(self:buffer.Buffer, offset:integer, value:integer)
        writeUInt16BE: function(self:buffer.Buffer, offset:integer, value:integer)
        writeInt16LE: function(self:buffer.Buffer, offset:integer, value:integer)
        writeInt16BE: function(self:buffer.Buffer, offset:integer, value:integer)
        writeUInt32LE: function(self:buffer.Buffer, offset:integer, value:integer)
        writeUInt32BE: function(self:buffer.Buffer, offset:integer, value:integer)
        writeInt32LE: function(self:buffer.Buffer, offset:integer, value:integer)
        writeInt32BE: function(self:buffer.Buffer, offset:integer, value:integer)
        toString: function(self:buffer.Buffer, i?:integer, j?:integer): string
        isBuffer: function(b:buffer.Buffer): boolean
    end
end

return buffer