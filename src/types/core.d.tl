local record core
    record Object
        initialize: function(self:Object)
        create: function(self:Object): Instance
        new: function(self:Object, ...:any): Instance
        extend: function(self:Object): Object
    end
    record Instance
    
    end
end
return core