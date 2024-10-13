local record middleclass
    _VERSION: string
    _DESCRIPTION: string
    _URL: string
    _LICENSE: string
    interface Class
        name: string                          -- Class name
        super: Class | nil                    -- Superclass reference
        static: table                         -- Static namespace for class methods
        new: function(self: Class, ...: any): Class      -- Constructor for creating new objects
        subclass: function(self: Class, name: string): Class -- Create a subclass
        isSubclassOf: function(self: Class, other: Class): boolean -- Check if a class is a subclass of another
        include: function(self: Class, ...: table): Class -- Include mixins
        subclassed: function(self: Class, other: Class): nil -- Hook for when a subclass is created
        initialize: function(self: Class, ...: any): nil -- Initialize method for instances
        allocate: function(self: Class): table           -- Allocate a new instance (low-level)
        isInstanceOf: function(self: table, class: Class): boolean -- Check if an object is an instance of a class    
    end
    class: function(name: string, super?: Class): Class -- Function to create a new class
    metamethod __call: function(self: middleclass, name: string, super?: Class): Class -- Function
end


return middleclass