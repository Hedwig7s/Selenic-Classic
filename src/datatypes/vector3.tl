--local require = require("customrequire")

local record Vector3
    __index: Vector3
    __add: function(self:Vector3, other:Vector3): Vector3
    __mul: function(self:Vector3, other:Vector3|number): Vector3
    __sub: function(self:Vector3, other:Vector3): Vector3
    __div: function(self:Vector3, other:Vector3|number): Vector3
    __idiv: function(self:Vector3, other:Vector3|number): Vector3
    __mod: function(self:Vector3, other:Vector3): Vector3
    __pow: function(self:Vector3, other:Vector3): Vector3
    __tostring: function(self:Vector3): string
    __eq: function(self:Vector3, other:Vector3): boolean
    x: number
    y: number
    z: number
    zero: Vector3
    one: Vector3
    xAxis: Vector3
    yAxis: Vector3
    zAxis: Vector3
    Magnitude: number
    Unit: Vector3
    new: function(x:number, y:number, z:number, skipUnit:boolean): Vector3
end
Vector3.__index = Vector3
Vector3.__add = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.x + other.x, self.y + other.y, self.z + other.z)
end
Vector3.__mul = function(self:Vector3, other:Vector3|number): Vector3
    if other is Vector3 then
        return Vector3.new(self.x * other.x, self.y * other.y, self.z * other.z)
    else
        return Vector3.new(self.x * other, self.y * other, self.z * other)
    end
end
Vector3.__sub = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.x - other.x, self.y - other.y, self.z - other.z)
end
Vector3.__div = function(self:Vector3, other:Vector3|number): Vector3
    if other is Vector3 then
        return Vector3.new(self.x / other.x, self.y / other.y, self.z / other.z)
    else
        return Vector3.new(self.x / other, self.y / other, self.z / other)
    end
end
Vector3.__idiv = function(self:Vector3, other:Vector3|number): Vector3
    if other is Vector3 then
        return Vector3.new(self.x // other.x, self.y // other.y, self.z // other.z)
    else
        return Vector3.new(self.x // other, self.y // other, self.z // other)
    end
end
Vector3.__mod = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.x % other.x, self.y % other.y, self.z % other.z)
end
Vector3.__pow = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.x ^ other.x, self.y ^ other.y, self.z ^ other.z)
end
Vector3.__tostring = function(self:Vector3): string
    return string.format("%d, %d, %d", self.x, self.y, self.z)
end
Vector3.__eq = function(self:Vector3, other:Vector3): boolean
    return self.x == other.x and self.y == other.y and self.z == other.z
end

function Vector3:Abs(): Vector3
    return Vector3.new(math.abs(self.x), math.abs(self.y), math.abs(self.z))
end

function Vector3:Cross(other:Vector3): Vector3
    return Vector3.new(self.y*other.z - self.z*other.y, self.z*other.x - self.x*other.z, self.x*other.y - self.y*other.x)
end

function Vector3:Dot(other:Vector3): number
    return self.x*other.x + self.y*other.y + self.z*other.z
end

function Vector3:FuzzyEq(other:Vector3, epsilon:number): boolean
    return math.abs(self.x - other.x) < epsilon and math.abs(self.y - other.y) < epsilon and math.abs(self.z - other.z) < epsilon
end

function Vector3:Lerp(other:Vector3, alpha:number): Vector3
    return Vector3.new(self.x + (other.x - self.x) * alpha, self.y + (other.y - self.y) * alpha, self.z + (other.z - self.z) * alpha)
end

function Vector3:Max(other:Vector3): Vector3
    return Vector3.new(math.max(self.x, other.x), math.max(self.y, other.y), math.max(self.z, other.z))
end

function Vector3:Min(other:Vector3): Vector3
    return Vector3.new(math.min(self.x, other.x), math.min(self.y, other.y), math.min(self.z, other.z))
end

function Vector3.new(x:number, y:number, z:number, skipUnit: boolean): Vector3
    local self:Vector3 = {}
    self.x = x
    self.y = y
    self.z = z
    self.Magnitude = math.sqrt(x*x + y*y + z*z)
    if not skipUnit then
        self.Unit = Vector3.new(x/self.Magnitude, y/self.Magnitude, z/self.Magnitude, true)
    end
    setmetatable(self, Vector3)
    return self
end


return Vector3