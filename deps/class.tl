local classes:{string:BaseClass} = {}
local singletons:{string:Instance} = {}

global record BaseClass 
    __name__:string
    __super__:BaseClass
    __values__:{string: any}
    metamethod __call: function(self:BaseClass, ...:any): Instance
    __singleton__: boolean
    __constructor__: function(self:Instance, super:BaseClass|nil, ...:any)
end

global record Instance
    __class__:BaseClass
end

global record ClassData
    implements: BaseClass|nil
    extends: BaseClass|nil
    values: {string: any}
    constructor: function(self:Instance, super:BaseClass|nil, ...:any)
    singleton: boolean|nil
end

local function implementsClass(class:BaseClass, implements:BaseClass): boolean
    for k, _ in pairs(implements.__values__) do
        if not class.__values__[k] then
            return false
        end
    end
    return true
end

local function extendsClass(class:BaseClass, extends:BaseClass): boolean
    local current = class
    while current do
        if current == extends then
            return true
        end
        current = current.__super__
    end
    return false
end

global function createClass(name:string, data:ClassData): BaseClass
    assert(data.constructor, "Class " .. name .. " must have a constructor")
    assert(name and name is string, "Class name must be a string")
    assert(not classes[name], "Class " .. name .. " already exists")
    local class:BaseClass = {
        __name__ = name,
        __singleton__ = data.singleton or false,
        __constructor__ = data.constructor,
    }
    setmetatable(class, {
        __call = function(self:BaseClass, ...): Instance
            if self.__singleton__ and singletons[self.__name__] then
                return singletons[self.__name__]
            end
            local instance:Instance = {
                __class__ = class
            }
            if class.__values__ then
                setmetatable(instance, {__index = class.__values__})
            end
            self.__constructor__(instance, class.__super__, ...)
            if self.__singleton__ then
                singletons[self.__name__] = instance
            end
            return instance
        end
    })
    if data.extends then
        class.__super__ = data.extends
        setmetatable(class, {__index = data.extends})
    end
    local implements = data.implements
    if implements is BaseClass and not implementsClass(class, implements) then
        for k, _ in pairs(implements.__values__) do
            error("Class " .. name .. " does not implement method " .. k)
        end
    end
    class.__values__ = data.values

    classes[name] = class
    return class
end

return createClass, {
    implements = implementsClass,
    extends = extendsClass
}
